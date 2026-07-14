variable "project_id" {
  type        = string
  description = "gcp-finops-monitor"
}

variable "region" {
  type        = string
  default     = "asia-southeast1"
  description = "The primary region for resources"
}

variable "billing_account_id" {
  type        = string
  description = "016BA5-8B3F3A-6B7D35"
}
