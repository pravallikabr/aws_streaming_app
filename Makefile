init:
	cd terraform/environments/$(env) && rm -rf .terraform/
	cd terraform/environments/$(env) && terraform init -backend=true -backend-config=backend.tfvars ../..



# Use this only in case the state file is corrupted
refresh: check-vars init
	cd terraform/environments/$(env) && terraform refresh ../..

plan:
	cd terraform/environments/$(env) && terraform plan -out .terraform/terraformout.plan ../..

apply:
	cd terraform/environments/$(env) && terraform apply -auto-approve .terraform/terraformout.plan

destroy: check-vars
	cd terraform/environments/$(env) && terraform destroy -auto-approve ../..