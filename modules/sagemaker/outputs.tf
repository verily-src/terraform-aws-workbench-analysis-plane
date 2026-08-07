output "notebook_lifecycle_configuration_arns" {
  value       = values(aws_sagemaker_notebook_instance_lifecycle_configuration.default)[*].arn
  description = "Landingzone's Sagemaker Notebook Lifecycle Configuration ARNs"
}

output "notebook_lifecycle_configuration_names" {
  value       = values(aws_sagemaker_notebook_instance_lifecycle_configuration.default)[*].name
  description = "Landingzone's Sagemaker Notebook Lifecycle Configuration names"
}
