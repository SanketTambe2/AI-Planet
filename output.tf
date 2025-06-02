#############################################
# Outputs

# Output the ECS Cluster ARN
output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster used for Prefect workers."
  value       = aws_ecs_cluster.prefect.arn
}

# Prefect Cloud instructions (marked as sensitive to avoid errors)
output "prefect_cloud_verification_instructions" {
  description = "Instructions to verify the work pool and worker in Prefect Cloud."
  value       = <<EOT
1. Log in to https://app.prefect.cloud/
2. Navigate to your workspace.
3. Go to Work Pools -> ecs-work-pool
4. Verify the 'dev-worker' is running and healthy.
5. Confirm that your flow runs are being picked up by the worker.
EOT
  sensitive   = true
}


