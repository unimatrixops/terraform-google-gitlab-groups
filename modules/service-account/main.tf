terraform {
  required_providers {
    gitlab = {
      source = "gitlabhq/gitlab"
      version = "3.7.0"
    }
    google = {
      version = "3.88.0"
    }
  }
}


variable "service_account" {
  type=object({
    project=string
    display_name=string
    group_id=string
  })
}


locals {
  name = "gitlab-group-${var.service_account.group_id}"
  display_name="GitLab group (${var.service_account.display_name})"
}


resource "google_service_account" "default" {
  project       = var.service_account.project
  account_id    = local.name
  display_name  = local.display_name
}


resource "time_rotating" "key" {
  rotation_days = 30
}


resource "google_service_account_key" "key" {
  service_account_id = google_service_account.default.name

  keepers = {
    rotation_time = time_rotating.key.rotation_rfc3339
  }
}


resource "gitlab_group_variable" "key" {
  group             = var.service_account.group_id
  key               = "GOOGLE_APPLICATION_CREDENTIALS"
  value             = base64decode(google_service_account_key.key.private_key)
  protected         = true
  masked            = false
  variable_type     = "file"
}
