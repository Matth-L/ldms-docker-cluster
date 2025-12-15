FROM logstash:8.19.8

RUN bin/logstash-plugin install logstash-output-opensearch
RUN bin/logstash-plugin install logstash-filter-opensearch
# fix the error : "Failed to load default template for OpenSearch v3 with ECS v8"
RUN set -x \
    && cp /usr/share/logstash/vendor/bundle/jruby/3.1.0/gems/logstash-output-opensearch-2.0.3-java/lib/logstash/outputs/opensearch/templates/ecs-v8/2x.json \ 
    /usr/share/logstash/vendor/bundle/jruby/3.1.0/gems/logstash-output-opensearch-2.0.3-java/lib/logstash/outputs/opensearch/templates/ecs-v8/3x.json   