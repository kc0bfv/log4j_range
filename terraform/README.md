# Setting up the Infrastructure

You may need to change the AWS profile in `blue.tf` to default, or whatever you have configured AWS with.  If you haven't configured aws, run `aws configure`.  Run the following commands:

```
ssh-keygen -f key
terraform init
terraform apply
```

# Editing the Code

Edit it.  Follow the current formatting.  Run the following commands afterwards to format the code and validate it.

```
terraform fmt
terraform validate
```

# References

https://learn.hashicorp.com/tutorials/terraform/aws-build?in=terraform/aws-get-started
