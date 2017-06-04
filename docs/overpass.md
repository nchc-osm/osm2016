# Title: OSM overpass server
# Tags: Linux
# Author: ThomasTsai
# Summary:![achavi](|filename|/images/osm-achavi.png) 建了一台overpass主機來玩 overpass turbo 和 achavi

安裝的方式wiki都有 可以先看看

Install

http://wiki.openstreetmap.org/wiki/Overpass_API/Installation#Software

基本上要準備的東西不少，大概是osm-3s, 準備database, 更新到最新資料, 設定apache2, 安裝overpass-turbo, 安裝 achavi。

因為新版的已經支援attic, 所以以下的指令都以需要attic來處理

因為很容易浪費時間解決地雷，所以強烈建議先看看 

Troubleshooting 

http://wiki.openstreetmap.org/wiki/Overpass_API/Installation#Troubleshooting

### osm-3s

編譯 osm-3s

    wget http://dev.overpass-api.de/releases/osm-3s_v0.7.52.tar.gz
    sudo aptitude install g++ make expat libexpat1-dev zlib1g-dev
    tar -zxvf osm-3s_v*.tar.gz
    cd osm-3s_v*
    ./configure CXXFLAGS="-O3" --prefix=$EXEC_DIR
    make install


### database
抓下來要一點時間...來看幾個mv吧^^

    wget -O $PLANET_FILE  "http://ftp.heanet.ie/mirrors/openstreetmap.org/planet-latest.osm.bz2"

//[   ] planet-latest.osm.bz2          2016-01-20 15:07   47G  

initial 的動作超久的，而且可能失敗要重來，而且以下的方式是沒有attic的

// EXEC_DIR is prefix, the default is /usr/local. --meta is optional

    nohup init_osm3s.sh $PLANET_FILE dbdir /usr/local --meta&
    tail -f nohup.out

所以 如果要 attic 所有的歷史紀錄，建議抓最舊的 planet檔案，用update的方式，慢慢處理，看怎麼抉擇摟。

我選擇只有新資料使用 attic。

完成之後，表示database基本已經好了，可以query看看

### database clone -- update 20160815

有時候會發生 db 有錯誤，又不想重新apply，建議用 clone 的方式, 以下的的meta是需要attic, 可以是 yes | no | attic, 看自己狀況摟

    mkdir -p clonedb
    bin/download_clone.sh --source=http://dev.overpass-api.de/api_drolbr/ --db-dir="db/" --meta=attic

### query

    $EXEC_DIR/bin/osm3s_query --db-dir=$DB_DIR
    input: <query type="node"><bbox-query n="51.0" s="50.9" w="6.9" e="7.0"/><has-kv k="amenity" v="pub"/></query><print/>

    ctrl+d

到這邊，別太開心，後面還有很多事情要處理，因為還沒有建area


### create areas
這邊需要一個叫作 "rules" 的檔案，tarball 沒包，github上才有。

    cp -pR "../rules" $DB_DIR
    nohup $EXEC_DIR/bin/dispatcher --areas --db-dir=$DB_DIR &
    chmod 666 "../db/osm3s_v0.7.*_areas"

以下是我踩到的地雷

    >> https://wiki.openstreetmap.org/wiki/Overpass_API/Installation#Area_batch_run_out_of_memory_error
    >> Area batch run out of memory error
    >> When generating an area run, you may receive the following:
    >> Query run out of memory in "recurse" at line 255 using about 1157 MB
    >> (Assuming you have enough physical free memory, 4gb worked for me) Try removing all the "area" files from your database directory and increase the element-limit (in your $DB_DIR/rules/rules.osm3s file) to "2073741824" 
    
    >> http://wiki.openstreetmap.org/wiki/Overpass_API/Overpass_QL#Element_limit_.28maxsize.29
    >> Element limit (maxsize)
    >> The maxsize setting has one parameter, a non-negative integer. Default value is 536870912 (512 MB).
    >> This parameter indicates the maximum allowed memory for the query in bytes RAM on the server, as expected by the user. 
    

處理好記憶體問題之後 area 才成功建好。

接下來繼續處理更新的部份

### update 
這邊也是一個腦殘的地方，程式需要知道資料庫更新到哪裡，才能抓之後的更新，且程式沒有佛心幫你判斷，所以，我是去看檔案的日期，到replication去找對應的ID，例如我的是 

    [   ] planet-latest.osm.bz2          2016-02-10 16:29   47G

而我打算做 hourly update, 所以到 http://planet.osm.org/replication/hour/ 去比對日期，怕資料沒有，所以往回追溯一個月，我選擇 第一個目錄是 028 裏面最舊的 000.osc.gz, 所以要更新的 ID會是 28000

    fetch_osc.sh 28000 "http://planet.osm.org/replication/hour/"  diff-hourly/

fetch_osc.sh 主要是下載，要更新到資料庫，要用另一隻程式 apply_osc_to_db.sh

    nohup ./apply_osc_to_db.sh $REPLICATE_DIR/ $FIRST_MINDIFF_ID  --meta=attic &

到這邊，資料庫算是準備好了。

接下來就是 apache2

### apache2 for web api

安裝，啟動相關模組

    sudo apt-get install apache2
    sudo a2enmod cgi
    sudo a2enmod ext_filter
    cd /etc/apache2/sites-available

編輯 site 設定檔 vi default

    <VirtualHost *:80>
    ServerAdmin webmaster@localhost
    ExtFilterDefine gzip mode=output cmd=/bin/gzip
    DocumentRoot [YOUR_HTML_ROOT_DIR]
    
    # This directive indicates that whenever someone types http://www.mydomain.com/api/ 
    # Apache2 should refer to what is in the local directory [YOUR_EXEC_DIR]/cgi-bin/
    ScriptAlias /api/ [YOUR_EXEC_DIR]/cgi-bin/
    
    
    # This specifies some directives specific to the directory: [YOUR_EXEC_DIR]/cgi-bin/
    <Directory "[YOUR_EXEC_DIR]/cgi-bin/">
    AllowOverride None
    Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch
    # For Apache 2.4:
    #  Order allow,deny
    # For Apache > 2.4:  
    Require all granted
    #SetOutputFilter gzip
    #Header set Content-Encoding gzip
    </Directory>
    
    ErrorLog /var/log/apache2/error.log
    
    # Possible values include: debug, info, notice, warn, error, crit, alert, emerg
    LogLevel warn
    
    CustomLog /var/log/apache2/access.log combined
    
    </VirtualHost>

存檔之後重新啟動

    sudo /etc/init.d/apache2 restart

### overpass-turbo and achavi
這個就簡單多了

先切換到var/www/html 下載後 改一下設定檔就好

#### overpass-turbo

    git clone https://github.com/tyrasd/overpass-turbo.git

編輯 config, vi js/config.js

    defaultServer: "http:// YURIP /api/",
    ...
    suggestedServers: [
    "http:// YURIP /api/",
    ...
    defaultMapView: {
      lat: 23.5,
      lon: 121.33,
      zoom: 8
    },
    ...

就可以了
連到 http:// YURIP /overpass-turbo/

像我的就是

![overpass nchc](|filename|/images/osm-overpass-overpassturbo.png)

#### achavi

如果有啟動 attic 可以看到 osm 的歷史紀錄
例如 
![achavi](|filename|/images/osm-achavi.png)

一樣是到 /var/www/html/

    git clone https://github.com/nrenner/achavi.git

編輯js檔，讓他使用自己的overpass主機, vi js/OverpassAPI.js, 建議用取代，把所有的 overpass-api.de 換成你的主機，如overpass.nchc.org.tw, diff 檔如下

	diff --git a/js/OverpassAPI.js b/js/OverpassAPI.js
	index ac708c6..0dd6738 100644
	--- a/js/OverpassAPI.js
	+++ b/js/OverpassAPI.js
	@@ -20,7 +20,7 @@ OverpassAPI.prototype.getSequenceUrl = function(sequence) {
	         c : s.substring(6, 9)
	     };
	     //var urlFormat = 'http://overpass-api.de/augmented_diffs/${a}/${b}/${c}.osc.gz';
	-    var urlFormat = 'https://overpass-api.de/augmented_diffs/id_sorted/${a}/${b}/${c}.osc.gz';
	+    var urlFormat = 'https://overpass.nchc.org.tw/augmented_diffs/id_sorted/${a}/${b}/${c}.osc.gz';
	    
	     var url = OpenLayers.String.format(urlFormat, path);
	     return url;
	@@ -40,7 +40,7 @@ OverpassAPI.prototype.parseSequence = function (request, url) {
	 
	 OverpassAPI.prototype.getCurrentSequence = function () {
	     var sequence = -1;
	-    var url = "https://overpass-api.de/augmented_diffs/state.txt";
	+    var url = "https://overpass.nchc.org.tw/augmented_diffs/state.txt";
	 
	     OpenLayers.Request.GET({
	         url: url,
	@@ -57,7 +57,7 @@ OverpassAPI.prototype.getCurrentSequence = function () {
	 OverpassAPI.prototype.getSequenceByTime = function (timestamp, callback) {
	     var osmBase = moment.utc(timestamp).format('YYYY-MM-DDTHH[\\]:mm[\\]:ss\\Z');
	     console.log('load time: ' + osmBase);
	-    var url = 'https://overpass-api.de/api/augmented_state_by_date?osm_base=' + osmBase;
	+    var url = 'https://overpass.nchc.org.tw/api/augmented_state_by_date?osm_base=' + osmBase;
	     console.log('requesting state ' + url);
	     OpenLayers.Request.GET({
	         url: url,
	@@ -82,7 +82,7 @@ OverpassAPI.prototype.loadByUrl = function(url) {
	 OverpassAPI.prototype.load = function(sequence, postLoadCallback) {
	     var bboxParam;
	     if (sequence && sequence >= 0) {
	-        var url = "https://overpass-api.de/api/augmented_diff?id=" + sequence + "&info=no";
	+        var url = "https://overpass.nchc.org.tw/api/augmented_diff?id=" + sequence + "&info=no";
	         //var url = getSequenceUrl(sequence);
	         if (!this.bbox) {
	             this.bbox = this.bboxControl.addBBoxFromViewPort();
	@@ -117,7 +117,8 @@ OverpassAPI.prototype.loadDiff = function(from, to, relations, postLoadCallback,
	     }
	     dateRange = '"' + mindate + '"' + maxdate;
	 
	-    var data_url = 'https://overpass-api.de/api/interpreter';
	+    //var data_url = 'https://overpass-api.de/api/interpreter';
	+    var data_url = 'https://overpass.nchc.org.tw/api/interpreter';
	     url = data_url + '?data=[adiff:' + dateRange
	         + '];(node(bbox)(changed);way(bbox)(changed);' + (relations ? 'relation(bbox)(changed);' : '') + ');out meta geom(bbox);';
	 


### 開機啟動
因為相關的 script 滿多的 所以我用 root跑以下的指令，我暫時先放到 rc.local, 以後再處理

    #!/bin/bash
    /home/user/osm/bin/dispatcher --terminate
    /home/user/osm/bin/dispatcher --terminate
    rm /home/user/osm/db/osm3s_v0.7.52_*
    rm /dev/shm/osm3s_v0.7.52_*
    /home/user/osm/bin/dispatcher --osm-base  --attic --db-dir=/home/user/osm/db/ &
    sleep 2
    /home/user/osm/bin/dispatcher --areas --attic --db-dir=/home/user/osm/db &
    chmod 666 /home/user/osm/db/osm3s_*
    chown www-data:www-data /home/user/osm/db/*
    sleep 10
    ### for update
    nid=$(cat /home/user/osm/db/replicate_id)
    /home/user/osm/bin/fetch_osc.sh $nid "http://planet.osm.org/replication/hour/"  /home/user/osm/diff-hourly/ &
    sleep 60
    /home/user/osm/bin/apply_osc_to_db.sh diff-hourly/ $nid --meta=attic &


ref: http://overpass-api.de/no_frills.html
ref: http://wiki.openstreetmap.org/wiki/Overpass_API/Installation
