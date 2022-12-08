
locals {
  role_prefix = var.account_type == "org_member" ? "${var.role_name_prefix}PrismaCloudOrgMember" : "${var.role_name_prefix}PrismaCloud"

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/SecurityAudit",
    "arn:aws:iam::aws:policy/AWSCloudFormationReadOnlyAccess"
  ]
}

resource "aws_iam_role" "this" {
  name               = var.protection_mode == "MONITOR_AND_PROTECT" ? "${local.role_prefix}ReadWriteRole" : "${local.role_prefix}ReadOnlyRole"
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

  tags = var.tags

}

resource "aws_iam_policy" "readonly" {
  for_each = { for path in fileset(path.module, "policies/read/*.json") : "${var.role_name_prefix}${split(".", basename(path))[0]}" => path }

  name        = "${var.role_name_prefix}${split(".", basename(each.value))[0]}"
  path        = "/"
  description = "${var.role_name_prefix}${split(".", basename(each.value))[0]}"
  policy      = file("${path.module}/${each.value}")
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "readonly" {
  for_each = aws_iam_policy.readonly

  role       = aws_iam_role.this.name
  policy_arn = each.value.arn
}

resource "aws_iam_policy" "readwrite" {
  for_each = var.protection_mode == "MONITOR_AND_PROTECT" ? { for path in fileset(path.module, "policies/write/*.json") : "${var.role_name_prefix}${split(".", basename(path))[0]}" => path } : {}

  name        = "${var.role_name_prefix}${split(".", basename(each.value))[0]}"
  path        = "/"
  description = "${var.role_name_prefix}${split(".", basename(each.value))[0]}"
  policy      = file("${path.module}/${each.value}")
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "managed_policy" {
  for_each = { for arn in toset(local.managed_policy_arns) : "AWSManaged-${split("/", arn)[1]}" => arn }

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

resource "aws_iam_role_policy_attachment" "readwrite" {
  for_each = aws_iam_policy.readwrite

  role       = aws_iam_role.this.name
  policy_arn = each.value.arn
}
