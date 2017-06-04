update

這邊也是一個重要的地方，程式需要知道資料庫更新到哪裡，才能抓之後的更新，且程式沒有幫你判斷，所以，是去看檔案的日期，到replication去找對應的ID，例如我的是

[   ] planet-latest.osm.bz2          2016-02-10 16:29   47G

而我打算做 hourly update, 所以到 http://planet.osm.org/replication/hour/ 去比對日期，怕資料沒有，所以往回追溯一個月，我選擇 第一個目錄是 028 裏面最舊的 000.osc.gz, 所以要更新的 ID會是 28000

fetch_osc.sh 28000 "http://planet.osm.org/replication/hour/"  diff-hourly/

fetch_osc.sh 主要是下載，要更新到資料庫，要用另一隻程式 apply_osc_to_db.sh

nohup ./apply_osc_to_db.sh $REPLICATE_DIR/ $FIRST_MINDIFF_ID  --meta=attic &

