# Setting up the Infrastructure

You may need to change the AWS profile in `blue.tf` to default, or whatever you have configured AWS with.  If you haven't configured aws, run `aws configure`.  Run the following commands:

```
ssh-keygen -f blue_key
ssh-keygen -f red_key
ssh-keygen -f admin_key
terraform init
terraform apply
```

Create a domain at `freedns.afraid.org` that your guacamole server will be at, and change it to v2 dynamic updates, and get the URL for updating the IPv4 and IPv6 addresses.  Rename "secrets.tf_TEMPLATE" to "secrets.tf", and put the URLs and domain in there where specified.  Make up some passwords for the VNC and Guacamole installs.

# Editing the Code

Edit it.  Follow the current formatting.  Run the following commands afterwards to format the code and validate it.

```
terraform fmt
terraform validate
```

# References

https://learn.hashicorp.com/tutorials/terraform/aws-build?in=terraform/aws-get-started
