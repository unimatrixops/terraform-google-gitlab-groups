

output "groups" {
  value = merge({
    for path, group in local.gitlab_groups:
    path => merge(group, {id = gitlab_group.groups[path].id})
  })
}
