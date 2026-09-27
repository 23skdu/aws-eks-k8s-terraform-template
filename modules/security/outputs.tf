##############################################################################
# modules/security/outputs.tf
##############################################################################

output "guardduty_detector_id" {
  description = "ID of the GuardDuty detector."
  value       = var.enable_guardduty ? aws_guardduty_detector.main[0].id : ""
}
