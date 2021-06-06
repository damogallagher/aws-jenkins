# Install jenkins on an ec2 instance
terraform apply -var="jenkinsInstanceName=[NAME OF INSTANCE]" -var="public_key=[PUBLIC SSH KEY]"  -auto-approve

e.g.

terraform apply -var="jenkinsInstanceName=JenkinsServer" -var="public_key=ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD3F6tyPEFEzV0LX3X8BsXdMsQz1x2cEikKDEY0aIj41qgxMCP/iteneqXSIFZBp5vizPvaoIR3Um9xK7PGoW8giupGn+EPuxIA4cDM4vzOqOkiMPhz5XK0whEjkVzTo4+S0puvDZuwIsdiW9mxhJc7tgBNL0cYlWSYVkz4G/fslNfRPW5mYAM49f4fhtxPb5ok4Q2Lg9dPKVHO/Bgeu5woMc7RY0p1ej6D4CKFE6lymSDJpW0YHX/wqE9+cfEauh7xZcG0q9t2ta6F6fmX0agvpFyZo8aFbXeUBr7osSCJNgvavWbM/06niWrOvYX2xwWdhXmXSrbX8ZbabVohBK41 email@example.com"  -auto-approve

## To obtain username and password for jenkins
Login to the instance

ssh -i [PATH TO PRIVATE SSH KEY] bitnami@[EC2 INSTANCE PUBLIC IP]

sudo cat /home/bitnami/bitnami_credentials

## Default Username
user

# Uninstall Jenkins
terraform destroy -auto-approve
