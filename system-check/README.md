## System check
System check about the project of OSM in 2016-2017.

### Author: Ceasar Sun

## Prepare system check script
Use script:  system-check.sh
Lcate file path , say: /script_path/system-check.sh

## Setup crontan for mirror
Add the follow in cronatb

	# system check and alert via mail if necessary
	8 * * * * root /script_path/system-check.sh > /dev/null


