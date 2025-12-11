Back to the main README.md : [here](../README.md)

# Connect to the node 

I followed the quickstart here : https://docs.opensearch.org/latest/security/getting-started

```sh
docker exec -it opensearch-node1 bash
sh plugins/opensearch-security/tools/install_demo_configuration.sh 
#  -> press Yes [y] to all
# Ctrl-D
```
Something should appear now, if not, wait a bit : 

```sh
curl -k -XGET -u admin:SecureP@ssword1 https://localhost:9200
```


# Adding new index pattern:

- http://localhost:5601
> Management > Dashboards Management > Index patterns.

# Creating a dataview

