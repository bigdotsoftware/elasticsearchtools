#!/bin/bash

if ! [ -x "$(command -v jq)" ]; then
  echo 'Error: jq is not installed.' >&2
  exit 1
fi

# format: my-es-host:9200
es_url=$1
indexpattern=$2
queryfile=$3
outputindex=$4

response=$(curl -s -XPOST "http://$es_url/$indexpattern/_search?track_total_hits=false" -H 'Content-Type: application/json' -d @$queryfile)

aggcounter=0
errorscounter=0
for row in $(echo "${response}" | jq -r '.aggregations.byhour.buckets[] | @base64'); do
    _jq() {
     echo ${row} | base64 --decode | jq -r ${1}
    }
   #echo $(_jq '.')
   key=$(_jq '.key')
   data=$(_jq '.')
   echo "Processing $key ..."
   response=$(curl -s -XPUT "http://$es_url/$outputindex/_doc/$key" -H 'Content-Type: application/json' -d "$data")
   #echo $response
   errorcheck=$(echo "$response" | jq '. | select(.error != null) | .error.root_cause')
   if [[ $errorcheck ]]; then
      errorscounter=$((errorscounter+1))
      echo $errorcheck
   fi
   aggcounter=$((aggcounter+1))
done

echo "DONE. Processed $aggcounter aggregations with $errorscounter errors to $indexpattern index"