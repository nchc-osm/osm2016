## Resource monitoring
Resource monitoring about the project of OSM in 2016-2017.

Reference:
How To Install the Munin Monitoring Tool on Debian 8 
https://www.digitalocean.com/community/tutorials/how-to-install-the-munin-monitoring-tool-on-debian-8

### Step 1 — Installing Required Packages

### Step 2 — Installing Munin on the Munin Master

### Step 3 — Configuring the Munin Master

Add your OSM relative node into monitor configuration in master: /etc/munin/munin.conf

	# OSM
	[OSM-TW.OSM]
	    address [your_OSM-TW_IP]
	    use_node_name yes


	[planet.OSM]
	    address [your_planet_IP]
	    use_node_name yes

	[umap.OSM]
	    address [your_umap_IP]
	    use_node_name yes

	[overpass.OSM]
	    address [your_overpass_IP]
	    use_node_name yes


### Step 4 — Adding a Node to Munin Master
Add allow IP for monitoring: /etc/munin/munin-node.conf
	# add allow IP (your munin master IP)

	allow ^xxx\.xx\.xx\.x$

