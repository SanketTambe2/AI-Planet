# AI-Planet
AI Planet Company Task 


# Prefect ECS Setup (Internship Task)

###########    What this does

This Terraform setup creates a VPC and related resources to run a Prefect worker on AWS ECS using Fargate.

It includes:
- VPC with subnets
- Internet and NAT Gateway
- ECS Cluster
- IAM role for the task
- Secrets Manager entries for Prefect
- ECS Task Definition and Service

---

##########     Why I did this

This is part of a DevOps internship assignment. I used Terraform because I'm more comfortable with it than CloudFormation, and it’s easier to manage.

---

########## How to run it

1. Install Terraform (I used version 1.5.0).
2. Set up AWS CLI and credentials.
3. Make sure you have your Prefect Cloud API key and other details.
4. Run the following in the project folder:

```bash
terraform init    ....(terraform init is First Cammand To run Your Terraform Project)
terraform plan    ....(terraform plan is a BluePrint Of Your Cpde And Infrastructure)
terraform apply   ....(terraform apply is a Execute your Code And Infrastructure)
terraform destroy ....(terraform destroy is a Destroy Or Delete Your All Infrastructure)

```

########## How to check if it works
1) Go to the ECS page in AWS Console → You should see a cluster called prefect-cluster.
2) Click into the service and see if one task is running.
3) Check Prefect Cloud under work pools → you should see a worker active in ecs-work-pool.
