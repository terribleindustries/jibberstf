# Jibbers Terraform

Creates a lambda to switch DNS records based on a new instance.

# Deploy
This is based on a few variables:

```route53_base_domain```
The base domain of the zone, this will be used to grab the zone id

```route53_domain```
The FEQN you want the stream to be. Two requirements here:
- This is the domain name you have in GitHub pages
- The record exists in route53, the TF can't create it since it's dynamic. The initial value can be anything.

```tag_name```
The name of the tag that the movienight box has, the value can be anything, the check is if the tag exists.

