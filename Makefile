ENV ?= dev
TFVARS := environments/$(ENV)/terraform.tfvars
TF := terraform

.PHONY: init validate fmt plan apply destroy output clean

init:
$(TF) init -upgrade

validate:
$(TF) validate

fmt:
$(TF) fmt -recursive

plan:
$(TF) plan 
-var-file=$(TFVARS) 
-var="db_password=$(DB_PASSWORD)" 
-out=tfplan.$(ENV)

apply:
$(TF) apply tfplan.$(ENV)

apply-auto:
$(TF) apply 
-var-file=$(TFVARS) 
-var="db_password=$(DB_PASSWORD)" 
-auto-approve

destroy:
$(TF) destroy 
-var-file=$(TFVARS) 
-var="db_password=$(DB_PASSWORD)"

output:
$(TF) output

clean:
rm -rf .terraform .terraform.lock.hcl tfplan.*

plan-vpc:
$(TF) plan 
-var-file=$(TFVARS) 
-var="db_password=$(DB_PASSWORD)" 
-target=module.vpc

plan-ec2:
$(TF) plan 
-var-file=$(TFVARS) 
-var="db_password=$(DB_PASSWORD)" 
-target=module.ec2

plan-rds:
$(TF) plan 
-var-file=$(TFVARS) 
-var="db_password=$(DB_PASSWORD)" 
-target=module.rds

state-list:
$(TF) state list
