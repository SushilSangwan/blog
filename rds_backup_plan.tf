resource "aws_backup_vault" "this" {
  count = var.create_rds_backup_plan ? 1 : 0

  name        = "${var.identifier}-backup-vault"
  kms_key_arn = module.kms.rds_kms_key_arn
  tags = merge(
    var.tags,
    {
      "Name"            = "${var.identifier}-backup-vault"
      "Schedule"        = "uk-office-hours"
      "confidentiality" = "internal"
    },
  )
}



resource "aws_backup_plan" "plan35" {
  count = var.create_rds_backup_plan ? 1 : 0
  name  = "Daily-35day-Retention"

  rule {
    rule_name                = "DailyBackups"
    start_window             = 480
    completion_window        = 10080
    enable_continuous_backup = false
    recovery_point_tags      = local.standard_tags
    schedule                 = "cron(0 5 ? * * *)"
    target_vault_name        = aws_backup_vault.this[0].name

    lifecycle {
      cold_storage_after = 0
      delete_after       = 35
    }
  }

  tags = { Name = "${var.identifier}-backup-plan" }
}

resource "aws_backup_selection" "myrdsbackup" {
  count        = var.create_rds_backup_plan ? 1 : 0
  name         = "${var.identifier}-backup-selection"
  plan_id      = aws_backup_plan.plan35[0].id
  iam_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/service-role/AWSBackupDefaultServiceRole"

  resources = [
    module.db_instance.this_db_instance_arn
  ]
}