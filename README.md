# Gitlab Local File

This repository contains a [Terraform](https://www.terraform.io/) module to create a local file.

## How do you use this module?

This folder defines a [Terraform module](https://www.terraform.io/docs/modules/usage.html), which you can use in your
code by adding a `module` configuration and setting its `source` parameter:

```hcl
module "gitlab_local_file" {
  source = "gitlab.com/mattkasa/gitlab-file/local"

  text = "Hello World"
  filename = "hello"
}
```
