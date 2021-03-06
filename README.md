
## Aggregate indices

It's always a good practice to keep pre-aggregated data wherever possible. For instance, do you need an information from past month about memory allocation and CPU usage with minute resolution? I bet no, so below is a very simple approach how to aggregate data and keep in in separate index.

Below example takes all documents from past 5h and aggregates them. So it's fine enough to schedule a cron job to execute it at least once per 5h. You can change metricsaggregation.json to tune up.

 <code>
./aggregate_beats_metrics.sh 'localhost:9200' 'metricbeat-*' 'metricsaggregation.json' 'metricbeat-agg'
 </code>
 
Alternatively, you may consider of using watcher (paid licence only). The workaround is to execute watcher once per day to calculate aggregations from the previous day. Personally I prefer and recommend first option with bash and cron, however such approach can be valuable in some use-cases.

 <code>
curl -XPUT 'http://localhost:9200/_watcher/watch/my-metricsaggregation-watch' -H 'Content-Type: application/json' -d @watcher.json
</code>


## Documents export

Below example shows how to scan an index from bash. You can change query.json to tune up.

 <code>
./scanindex.sh 'localhost:9200' my_index 'query.json' /root/backups/my_index_backup
 </code>
 
