#-------------------------------------------------------------------------------
#
#   GITLAB GROUP (GOOGLE)
#
#   Configures a Gitlab project using Google Cloud Platform as the supporting
#   infrastructure.
#
#-------------------------------------------------------------------------------


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
  gitlab_groups = {
    for x in var.gitlab_groups:
    "${x.parent}/${x.path}" => merge(x, {
      parent_id=data.gitlab_group.parents[x.parent].id
      qualname="${x.parent}/${x.path}"
      service_account=try(x.service_account, null)
    })
  }
}


data "gitlab_group" "parents" {
  for_each  = toset([for k, v in var.gitlab_groups: v.parent])
  full_path = each.value
}


resource "gitlab_group" "groups" {
  for_each                = local.gitlab_groups
  name                    = each.value.name
  path                    = each.value.path
  parent_id               = each.value.parent_id
  description             = try(each.value.description, null)
  lfs_enabled             = try(each.value.lfs_enabled, false)
  request_access_enabled  = try(each.value.request_access_enabled, false)
  visibility_level        = try(each.value.visibility_level, "private")
  auto_devops_enabled     = try(each.value.auto_devops_enabled, false)
  emails_disabled         = try(each.value.emails_disabled, false)
  mentions_disabled       = try(each.value.mentions_disabled, false)

  require_two_factor_authentication = false
  two_factor_grace_period           = 48
  subgroup_creation_level           = "owner"
  project_creation_level            = "maintainer"
  share_with_group_lock             = false
}


module "service-account" {
  source          = "./modules/service-account"

  service_account = merge(each.value.service_account, {
    group_id=gitlab_group.groups[each.key].id
    display_name=gitlab_group.groups[each.key].name
  })

  for_each = {
    for k, v in local.gitlab_groups:
    k => v if v.service_account != null
  }
}


module "secrets" {
  depends_on  = [gitlab_group.groups]
  for_each = {for path, project in local.gitlab_groups:
    path => project
    if try(project.secrets, []) != []
  }
  source = "./modules/secrets"
  gitlab_group = each.value
}
