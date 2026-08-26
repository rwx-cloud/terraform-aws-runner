output "provisioning_role_arn" {
  description = "ARN of the role RWX assumes to manage runners in this account."
  value       = aws_iam_role.provisioning.arn
}

output "provisioning_role_name" {
  description = "Name of the role RWX assumes to manage runners in this account."
  value       = aws_iam_role.provisioning.name
}

output "instance_role_arn" {
  description = "ARN of the role that runner instances run as. Attach additional policies to it to grant your runners access to other AWS resources."
  value       = aws_iam_role.runner.arn
}

output "instance_role_name" {
  description = "Name of the role that runner instances run as."
  value       = aws_iam_role.runner.name
}

output "instance_profile_arn" {
  description = "ARN of the instance profile attached to runner instances."
  value       = aws_iam_instance_profile.runner.arn
}
