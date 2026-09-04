variable "github_org" {
  type        = string
  description = "GitHub organization or username"
  default     = "CHANGE_ME"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository name"
  default     = "railfleet-devops-mvp"
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}
