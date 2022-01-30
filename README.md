# AWS Terraform starter kits
Provide basic building blocks for terraform. This mean to serve rails app ( 6.x.x ).
We build this to manage VTENH infrastructure in AWS cloud. Contribution is welcome to extend beyond our need to other use cases.

## GET STARTED

Rename **variables.config.tf.example**  -> **variables.config.tf** and enter your credentials accordingly

```
terraform init
terraform plan
terraform apply
terraform output
```

## SHORT HANDED ALIAS
For convenience, we use the following alias

```
alias "tfi"="terraform init"
alias "tfp"="terraform plan"
alias "tfa"="terraform apply"
alias "tfo"="terraform output"
alias "tfs"="terraform state"
```

## DETACHED STATE
The following have been removed from state management in terraform

```
tfs rm module.sg.aws_security_group.quicksight
tfs rm module.sg.aws_security_group.postgresql_replica
```

## ECS EC2
Amazon might raise a waring with an outdated agent because your image_id for example (mi-0eb977d074b57acc0) have an ecs outdated version. To get the latest image_id
go to https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI.html and pick your region and then open it up to get the latest ami and finally
update your image_id config.

```
variable "image_id" {
  # https://ap-southeast-1.console.aws.amazon.com/systems-manager/parameters/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id/description?region=ap-southeast-1#
  default = "ami-0eb977d074b57acc0"
}

# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI.html
variable "instance_type" {
  default = "t3.small"
}
```

## ECS EC2
Amazon might raise a waring with an outdated agent because your image_id for example (mi-0eb977d074b57acc0) have an ecs outdated version. To get the latest image_id
go to https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI.html and pick your region and then open it up to get the latest ami and finally
update your image_id config.

```
variable "image_id" {
  # https://ap-southeast-1.console.aws.amazon.com/systems-manager/parameters/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id/description?region=ap-southeast-1#
  default = "ami-0eb977d074b57acc0"
}
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI.html
variable "instance_type" {
  default = "t3.small"
}
```

## ECS exec
Amazon ECS exec allows you to run code inside the container via SSM:  https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-exec.html

First you need to enable exec command in ecs service and then install this aws plugin called session manager:  https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html#install-plugin-macos.


Run the following command to check if the session-manager-plugin is installed successfully:

```
session-manager-plugin
```
And then add necessary permission to IAM role, and finally run

```
aws ecs execute-command \
  --region ap-southeast-1 \
  --profile vtenh \
  --cluster VTENH-fargate \
  --task 3c879816c3244e0ea58dfda4d8991678 \
  --container VTENH-fargate \
  --command "/bin/sh" \
  --interactive
```

## CONTRIBUTION
PRs are more than welcome.
