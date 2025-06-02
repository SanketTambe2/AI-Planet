################################################################################################


# VPC with DNS enabled
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "prefect-ecs-vpc" }
}

# Public Subnets
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags                    = { Name = "prefect-ecs-public-subnet-1" }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags                    = { Name = "prefect-ecs-public-subnet-2" }
}

resource "aws_subnet" "public_3" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1c"
  map_public_ip_on_launch = true
  tags                    = { Name = "prefect-ecs-public-subnet-3" }
}

# Private Subnets
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1a"
  tags              = { Name = "prefect-ecs-private-subnet-1" }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = "us-east-1b"
  tags              = { Name = "prefect-ecs-private-subnet-2" }
}

resource "aws_subnet" "private_3" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.6.0/24"
  availability_zone = "us-east-1c"
  tags              = { Name = "prefect-ecs-private-subnet-3" }
}

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "prefect-ecs-igw" }
}

# Public Route Table and Routes
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "prefect-ecs-public-rt" }
}

resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

# Associate Public Subnets
resource "aws_route_table_association" "public_assoc_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public_assoc_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public_assoc_3" {
  subnet_id      = aws_subnet.public_3.id
  route_table_id = aws_route_table.public.id
}




# NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "prefect-ecs-nat-eip" }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1.id
  depends_on    = [aws_internet_gateway.gw]
  tags          = { Name = "prefect-ecs-nat-gw" }
}

# Private Route Table and Routes
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "prefect-ecs-private-rt" }
}

resource "aws_route" "private_nat_access" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

# Associate Private Subnets
resource "aws_route_table_association" "private_assoc_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}
resource "aws_route_table_association" "private_assoc_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id
}
resource "aws_route_table_association" "private_assoc_3" {
  subnet_id      = aws_subnet.private_3.id
  route_table_id = aws_route_table.private.id
}

# Security Groups
resource "aws_security_group" "public_sg_vpc" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "prefect-ecs-public-sg" }
}

resource "aws_security_group" "private_sg_vpc" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "prefect-ecs-private-sg" }
}




#######################################################################################

# Cloud Map Private DNS Namespace
resource "aws_service_discovery_private_dns_namespace" "prefect_namespace" {
  name        = "default.prefect.local"
  description = "Private DNS namespace for Prefect ECS"
  vpc         = aws_vpc.main.id

  tags = {
    Name = "prefect-cloudmap-namespace"
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "prefect" {
  name = "prefect-cluster"

  service_connect_defaults {
    namespace = aws_service_discovery_private_dns_namespace.prefect_namespace.arn
  }

  tags = {
    Name = "prefect-cluster"
  }
}




##########################################################################
# IAM Role for ECS Task Execution

resource "aws_iam_role" "prefect_task_execution_role" {
  name = "prefect-task-execution-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Attach the ECS Task Execution managed policy
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.prefect_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Inline policy for Secrets Manager access
resource "aws_iam_role_policy" "ecs_task_secrets_manager_policy" {
  name = "ecs-task-secrets-manager-access"
  role = aws_iam_role.prefect_task_execution_role.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "*"
    }
  ]
}
POLICY
}

#######################################################################################
# Secrets Manager - Prefect Secrets


resource "aws_secretsmanager_secret" "prefect_api_key" {
  name = "prefect-api-key-1"
}

resource "aws_secretsmanager_secret_version" "prefect_api_key_version" {
  secret_id     = aws_secretsmanager_secret.prefect_api_key.id
  secret_string_wo = "pnu_2thQQwSIt2dxm982v5CrJTUzqUkO6g06vEjY"  # Replace with your actual Prefect API key
}

resource "aws_secretsmanager_secret" "prefect_account_id" {
  name = "prefect-account-id-new"
}

resource "aws_secretsmanager_secret_version" "prefect_account_id_version" {
  secret_id     = aws_secretsmanager_secret.prefect_account_id.id
  secret_string = "edd6d0c2-b26c-4041-87b9-44a1bbb2641f"  # Replace accordingly
}

resource "aws_secretsmanager_secret" "prefect_workspace_id" {
  name = "prefect-workspace-id-new"
}

resource "aws_secretsmanager_secret_version" "prefect_workspace_id_version" {
  secret_id     = aws_secretsmanager_secret.prefect_workspace_id.id
  secret_string = "b16149b6-b009-4222-a19d-da4e17c01f80"  # Replace accordingly
}

resource "aws_secretsmanager_secret" "prefect_account_url" {
  name = "prefect-account-url-new"
}

resource "aws_secretsmanager_secret_version" "prefect_account_url_version" {
  secret_id     = aws_secretsmanager_secret.prefect_account_url.id
  secret_string = "https://app.prefect.cloud/my/profile"  # Replace accordingly
}

#################################################################################################
# ECS Task Definition


resource "aws_ecs_task_definition" "dev_worker" {
  family                   = "dev-worker"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.prefect_task_execution_role.arn
  task_role_arn            = aws_iam_role.prefect_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "prefect-worker"
      image     = "prefecthq/prefect:2-latest"
      essential = true

      secrets = [
        {
          name      = "PREFECT_API_KEY"
          valueFrom = aws_secretsmanager_secret.prefect_api_key.arn
        },
        {
          name      = "PREFECT_ACCOUNT_ID"
          valueFrom = aws_secretsmanager_secret.prefect_account_id.arn
        },
        {
          name      = "PREFECT_WORKSPACE_ID"
          valueFrom = aws_secretsmanager_secret.prefect_workspace_id.arn
        },
        {
          name      = "PREFECT_ACCOUNT_URL"
          valueFrom = aws_secretsmanager_secret.prefect_account_url.arn
        }
      ]

      environment = [
        {
          name  = "PREFECT_WORK_POOL_NAME"
          value = "ecs-work-pool"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/dev-worker"
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

#################################################################################
# ECS Service

resource "aws_ecs_service" "dev_worker_service" {
  name            = "dev-worker-service"
  cluster         = aws_ecs_cluster.prefect.id
  task_definition = aws_ecs_task_definition.dev_worker.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [
      aws_subnet.private_1.id,
      aws_subnet.private_2.id,
      aws_subnet.private_3.id,
    ]
    security_groups  = [aws_security_group.private_sg_vpc.id]
    assign_public_ip = false
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution_role_policy,
    aws_iam_role_policy.ecs_task_secrets_manager_policy
  ]
}







