#!/bin/bash

if ! [ -x "$(command -v jq)" ]; then
  echo 'Error: jq is not installed.' >&2
  exit 1
fi

# in format: my-es-host:9200
es_url=$1
index=$2
queryfile=$3
outputfolder=$4

response=$(curl -H 'Content-Type: application/json' -s $es_url/$index/_search?scroll=1m -d @$queryfile)
#echo $response
scroll_id=$(echo $response | jq -r ._scroll_id)
hits_count=$(echo $response | jq -r '.hits.hits | length')
hits_so_far=hits_count
echo Got initial response with $hits_count hits and scroll ID $scroll_id

if [ -z "$scroll_id" ]; then
      echo "\$scroll_id is empty"
      exit
fi

# TODO process first page of results here
suffix=_pagescan_
pagescan=1

echo "#!/bin/bash" > $outputfolder/import_$index.sh

echo "${response}" | jq -c '.hits.hits' > $outputfolder/$index$suffix$pagescan.json
jq -c '.[]|{index:{_index:._index, _type:._type,_id:._id}},._source' $outputfolder/$index$suffix$pagescan.json > $outputfolder/bulk_$index$suffix$pagescan.json
echo "curl -XPOST http://localhost:9200/_bulk -H 'Content-Type: application/x-ndjson' --data-binary \"@bulk_$index$suffix$pagescan.json\"" >> $outputfolder/import_$index.sh
echo "echo \"\"" >> $outputfolder/import_$index.sh
echo "echo \"------\"" >> $outputfolder/import_$index.sh

pagescan=$((pagescan+1))

while [ "$hits_count" != "0" ]; do
  response=$(curl -H 'Content-Type: application/json' -s $es_url/_search/scroll -d "{ \"scroll\": \"1m\", \"scroll_id\": \"$scroll_id\" }")
  scroll_id=$(echo $response | jq -r ._scroll_id)
  hits_count=$(echo $response | jq -r '.hits.hits | length')
  hits_so_far=$((hits_so_far + hits_count))
  echo "Got response with $hits_count hits (hits so far: $hits_so_far), new scroll ID $scroll_id"
  echo "${response}" | jq -c '.hits.hits' > $outputfolder/$index$suffix$pagescan.json
  jq -c '.[]|{index:{_index:._index, _type:._type,_id:._id}},._source' $outputfolder/$index$suffix$pagescan.json > $outputfolder/bulk_$index$suffix$pagescan.json
  echo "curl -XPOST http://localhost:9200/_bulk -H 'Content-Type: application/x-ndjson' --data-binary \"@bulk_$index$suffix$pagescan.json\"" >> $outputfolder/import_$index.sh
  echo "echo \"\"" >> $outputfolder/import_$index.sh
  echo "echo \"------\"" >> $outputfolder/import_$index.sh
  #processhits "$response" "$outputfolder/$index$suffix$pagescan.json"
  pagescan=$((pagescan+1))
done

echo $index Done!