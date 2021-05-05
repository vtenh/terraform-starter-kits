# AWS Terraform starter kits
Provide basic buiding blocks for terraform. This mean to serve rails app ( 6.x.x ).
We build this to manage VTENH infrastructure in AWS cloud. Constribution is welcome to extend beyond our need to other usecases.

## GET STARTED

Rename **variables.config.tf.example**  -> **variables.config.tf** and enter your credentials accordingly

```
terrform init
terraform plan
terraform apply
terraform output
```

## SHORT HANDED ALIAS
For convenience, we use the following alias

```
alias "tfi"="terrform init"
alias "tfp"="terraform plan"
alias "tfa"="terraform apply"
alias "tfo"="terraform output"
```

## DETACHED STATE
The following have been removed from state management in terraform

```
tfs rm module.sg.aws_security_group.quicksight
tfs rm module.sg.aws_security_group.postgresql_replica
```

## CONSTRIBUTION
PRs are more than welcome.
