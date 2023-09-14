# Here's where we'll put our Make commands

greeting:
	echo 'hello'

math:
	expr 2 + 2

directories:
	-mkdir tmp
	-mkdir data

downloads:
	curl "https://www.imf.org/external/datamapper/api/v1/PCPIPCH?periods=2023" -o tmp/inflation.json
	curl "https://www.imf.org/external/datamapper/api/v1/countries" -o tmp/countries.json

freshdata:
	node imf_to_csv.js

all: directories downloads freshdata

droughtmap:
	# get and unzip the drought map
	# get the url, output it in tmp directory as {name of the file}
	curl "https://droughtmonitor.unl.edu/data/shapefiles_m/USDM_current_M.zip" -o tmp/USDM_current_M.zip
	# unzip, override it if it already exists, unzip the file, destination is ./tmp
	unzip -o ./tmp/USDM_current_M.zip -d ./tmp

	# color the drought map, output as geojson
	# run mapshaper input
	npx mapshaper -i ./tmp/USDM_*.shp \
	-simplify percentage=25% resolution=1000x800 \
	-classify field=DM colors=OrRd breaks=1,2,3,4 \
	-style stroke=none \
	-o format=geojson ./tmp/drought.json

	# get the states map from the US census https://www.census.gov/geographies/mapping-files/time-series/geo/cartographic-boundary.html
	curl https://www2.census.gov/geo/tiger/GENZ2020/shp/cb_2020_us_state_20m.zip -o ./tmp/cb_2020_us_state_20m.zip
	unzip -o ./tmp/cb_2020_us_state_20m.zip -d ./tmp

	# make the state gray-filled map base
	npx mapshaper -i ./tmp/cb_2020_us_state_20m.shp \
	-simplify percentage=60% resolution=1000x800 \
	-style stroke='#a0a0a0' stroke-width=0.5 fill=#E6E6E6 \
	-o format=geojson ./tmp/us_states.json

	# combine the drought and state maps and output as an svg
	npx mapshaper -i ./tmp/us_states.json ./tmp/drought.json combine-files \
	-proj albersusa +PR \
	-o format=svg ./data/droughtmap.svg

