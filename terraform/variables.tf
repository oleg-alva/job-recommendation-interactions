variable "gcp_project" {
    description = "The GCP project ID"
    type        = string
    default     = "alva-analytics"
}

variable "project_name" {
    description = "The name of the project/application"
    type        = string
    default     = "job-recommendation-interactions"
}

variable "gcs_region" {
    description = "The region for GCS resources"
    type        = string
    default     = "europe-west4"
}

variable "gcs_location" {
    description = "The location for GCS resources"
    type        = string
    default     = "europe"
}

# Expect user input for image location
variable "image_location" {
    description = "Google Artifact Registry Image Location"
    type = string
    default = "europe-docker.pkg.dev/alva-analytics/job-recommendation-interactions/job-recommendation-interactions"
}