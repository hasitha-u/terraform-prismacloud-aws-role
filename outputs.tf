output "role_arn" {
  value       = aws_iam_role.this.arn
  description = "Prisma Cloud AWS IAM Role ARN"
}