
locals {
  role_prefix = var.account_type == "org_member" ? "${var.role_name_prefix}PrismaCloudOrgMember" : "${var.role_name_prefix}PrismaCloud"

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/SecurityAudit",
    "arn:aws:iam::aws:policy/AWSCloudFormationReadOnlyAccess"
  ]
}

resource "aws_iam_role" "this" {
  provider           = aws.account
  name               = var.protection_mode == "" ? "${local.role_prefix}ReadWriteRole" : "${local.role_prefix}ReadOnlyRole"
  assume_role_policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Principal": {
				"AWS": "arn:aws:iam::188619942792:root"
			},
			"Action": "sts:AssumeRole",
			"Condition": {
				"StringEquals": {
					"sts:ExternalId": [
						"${var.external_id}"
					]
				}
			}
		}
	]
}
EOF

}

resource "aws_iam_policy" "readonly" {
  for_each = { for path in fileset(path.module, "policies/read/*.json") : split(".", basename(path))[0] => path }

  provider    = aws.account
  name        = split(".", basename(each.value))[0]
  path        = "/"
  description = split(".", basename(each.value))[0]
  policy      = file("${path.module}/${each.value}")
}

resource "aws_iam_role_policy_attachment" "readonly" {
  for_each = aws_iam_policy.readonly

  provider   = aws.account
  role       = aws_iam_role.this.name
  policy_arn = each.value.arn
}

resource "aws_iam_policy" "readwrite" {
  for_each = var.protection_mode == "MONITOR_AND_PROTECT" ? { for path in fileset(path.module, "policies/write/*.json") : split(".", basename(path))[0] => path } : {}

  provider    = aws.account
  name        = split(".", basename(each.value))[0]
  path        = "/"
  description = split(".", basename(each.value))[0]
  policy      = file("${path.module}/${each.value}")
}

resource "aws_iam_role_policy_attachment" "managed_policy" {
  for_each = { for arn in toset(local.managed_policy_arns) : "AWSManaged-${split("/", arn)[1]}" => arn }

  provider   = aws.account
  role       = aws_iam_role.this.name
  policy_arn = each.value
}

resource "aws_iam_role_policy_attachment" "readwrite" {
  for_each = aws_iam_policy.readwrite

  provider   = aws.account
  role       = aws_iam_role.this.name
  policy_arn = each.value.arn
}