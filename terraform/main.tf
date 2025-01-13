provider "google" {
    project = var.gcp_project
}

# Local variables
locals {
    roles = [
        "roles/bigquery.user",
        "roles/bigquery.dataEditor",
        "roles/run.invoker"
    ]

    datasets = [
        # TODO: Add your datasets here
    ]

    env_vars = {
        PROJECT_ID = var.gcp_project
        REGION = var.gcs_location
        DATASET = google_bigquery_dataset.dataset.dataset_id
    }
}

# Service account for project
resource "google_service_account"  "runtime_account" {
    project = var.gcp_project
    account_id = "${var.project_name}-runtime"
    lifecycle {
      prevent_destroy = true
    }
}

resource "google_service_account_key" "runtime_account_key" {
    service_account_id = google_service_account.runtime_account.name
}

# Local file for service account json
resource "local_file" "google_service_account_keyfile" {
    content = base64decode(google_service_account_key.runtime_account_key.private_key)
    filename = "../google-service-account-${var.project_name}-runtime.json"
}

# Project level permission for service account
resource "google_project_iam_member" "project_user" {
  project = var.gcp_project
  for_each = toset(local.roles)
  role    = each.value
  member  = "serviceAccount:${google_service_account.runtime_account.email}"
}

# Bigquery dataset
resource "google_bigquery_dataset" "dataset" {
    dataset_id = var.project_name
    description = "Dataset for ${var.project_name}"
    location = "EU"
}

# Permissions to view source data from BigQuery
resource "google_bigquery_dataset_iam_member" "data_viewer" {
    role         = "roles/bigquery.dataViewer"
    for_each = toset(local.datasets)
    project = split(".", each.key)[0]
    dataset_id = split(".", each.key)[1]
    member = "serviceAccount:${google_service_account.runtime_account.email}"
} 

# Artifact registry
resource "google_artifact_registry_repository" "dbt_pipeline_repo" {
    location = var.gcs_location
    repository_id = var.project_name
    description = "Docker repository for ${var.project_name} transformation"
    format = "DOCKER"
}

# Cloud Run job
resource "google_cloud_run_v2_job" "transformation_job" {
    name     = "${var.project_name}-transformation-job"
    location = var.gcs_region
    template {
        template {
            containers {
                image = var.image_location
                dynamic "env" {
                    for_each = local.env_vars
                    content {
                        name  = env.key
                        value = env.value
                    }
                }

                resources {
                    limits = {
                        cpu    = 2
                        memory = "8Gi"
                    }
                }
            }
            service_account = google_service_account.runtime_account.email
            max_retries     = 1
        }
    }
}

# Cloud scheduler
resource "google_cloud_scheduler_job" "dbt_pipeline_scheduler" {
    name = "${var.project_name}-transformation-job"
    description = "Runs transformations for ${var.project_name} data every 5 minutes"
    schedule = "*/5 * * * *"
    attempt_deadline = "320s"
    region = "europe-west3"
    project = var.gcp_project
    retry_config {
      retry_count = 3
    }
    http_target {
        http_method = "POST"
        uri = "https://${var.gcs_region}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${var.gcp_project}/jobs/${google_cloud_run_v2_job.transformation_job.name}:run"
        oauth_token {
          service_account_email = google_service_account.runtime_account.email
        }
    }
}

resource "google_monitoring_alert_policy" "cloud_run_failure_policy" {
  display_name = "Cloud Run Job Failure Alert"
  combiner     = "AND"
  conditions {
    display_name = "Execution Failures in Cloud Run"
    condition_prometheus_query_language {
      rule_group = "over 10 failures in an hour"
      query = <<-EOT
        sum(increase(run_googleapis_com:job_completed_execution_count{monitored_resource="cloud_run_job",job_name="${var.project_name}-transformation-job",result="failed"}[1h])) > 10
      EOT
      duration  = "60s"
      evaluation_interval = "600s"
    }
  }

  alert_strategy {
    auto_close = "1800s"
  }

  notification_channels = [google_monitoring_notification_channel.email_channel.name]

  severity = "ERROR"

  documentation {
    subject = "${var.project_name} transformation failure"
    content = "More than 10 failures in Cloud Run ${var.project_name}-transformation-job during the past hour."
    mime_type = "text/markdown"
  }
}

resource "google_monitoring_notification_channel" "email_channel" {
  display_name = "Analytics Email Channel"
  type         = "email"
  labels = {
    email_address = "oleg@alvalabs.io" # TODO: change to appropriate google group
  }
}