# 1. Storage Bucket for Cloud Function Source Code
resource "google_storage_bucket" "function_bucket" {
  name                        = "${var.project_id}-function-source"
  location                    = var.region
  uniform_bucket_level_access = true
}

# 2. Cloud Function (Gen 2) definition
resource "google_cloudfunctions2_function" "finops_function" {
  name        = "finops-cost-monitor"
  location    = var.region
  description = "Queries billing daily and exports data to cloud monitoring"

  build_config {
    runtime     = "python311"
    entry_point = "main" # Matches the function name inside your main.py
    environment_variables = {
      BUILD_CONFIG_TEST = "true"
    }
    source {
      storage_source {
        bucket = google_storage_bucket.function_bucket.name
        object = "source.zip" # GitHub actions will upload this zip file
      }
    }
  }

  service_config {
    max_instance_count = 1
    available_memory   = "256M"
    timeout_seconds    = 60
    environment_variables = {
      PROJECT_ID         = var.project_id
      BILLING_ACCOUNT_ID = var.billing_account_id
    }
  }
}

# 3. Cloud Scheduler (Daily Trigger at 08:00 AM)
resource "google_cloud_scheduler_job" "daily_trigger" {
  name             = "daily-cost-monitor-trigger"
  description      = "Triggers the cost monitor function every morning"
  schedule         = "0 8 * * *"
  time_zone        = "Utc"
  attempt_deadline = "320s"

  http_target {
    http_method = "POST"
    uri         = google_cloudfunctions2_function.finops_function.service_config[0].uri

    oidc_token {
      service_account_email = "github-actions-deployer@${var.project_id}.iam.gserviceaccount.com"
    }
  }
}
