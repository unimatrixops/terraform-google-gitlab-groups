

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


locals {
  secrets = {
    for secret in var.gitlab_group.secrets:
    secret.name => merge(secret, {
      group=var.gitlab_group.qualname
      environment_scope=try(secret.environment_scope, "*")
      value=try(
        data.google_secret_manager_secret_version.secrets[secret.name].secret_data,
        secret.value
      )
    })
  }
}

data "google_secret_manager_secret_version" "secrets" {
  for_each = {
    for secret in var.gitlab_group.secrets:
    secret.name => secret if secret.kind == "google"
  }

  project = each.value.storage.project
  secret  = each.value.storage.name
}


resource "gitlab_group_variable" "plain" {
  for_each = {
    for key, secret in local.secrets:
    key => secret if secret.kind == "plain"
  }

  group             = each.value.group
  key               = each.value.name
  value             = each.value.value
  protected         = true
  masked            = try(each.value.masked, false)
  variable_type     = try(each.value.variable_type, "env_var")
}


resource "gitlab_group_variable" "google" {
  for_each = {
    for key, secret in local.secrets:
    key => secret if secret.kind == "google"
  }

  group             = each.value.group
  key               = each.value.name
  value             = each.value.value
  protected         = true
  masked            = try(each.value.masked, false)
  variable_type     = try(each.value.variable_type, "env_var")
}
