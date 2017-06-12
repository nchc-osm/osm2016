# Mirror OSM planet 

Reference: http://wiki.openstreetmap.org/wiki/Planet.osm

## Prepare mirror script
User script:  mirror-osm.planet 
Lcate file path , say: /script_path/mirror-osm.planet

## Setup crontan for mirror
Add the follow in cronatb
25    3 * * *	[miror_user]	/script_path/mirror-osm.planet

## Setup Apache virtual host for OSm planet

	<VirtualHost *:80>

        #
        # Place this config file into : /etc/apache2/sites-available [for Apache2]
        # then enable this virtual host for Planet
        #

        ServerAdmin [your_webmaster_email.address]
        ServerName planet.[your-domain]

        DocumentRoot /[your_planet_mirror_storage]/
		<Directory />
		        Options FollowSymLinks
		        AllowOverride None
		</Directory>
		<Directory /[your_planet_mirror_storage]/>
		        Options Indexes FollowSymLinks MultiViews
		        AllowOverride ALL
		        Order allow,deny
		        allow from all
		</Directory>

	</VirtualHost>
