terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

# Configure the GitHub Provider
provider "github" {
    owner = var.github_organization
    token = var.github_token # token must have admin read rights + secrets write
}

#
#
#

## REQUIRED
data "github_actions_public_key" "repo" {
  for_each = var.orchestrated_repositories
  repository = each.key
}

#
resource "github_actions_variable" "PRIVATE_REPOSITORY_IMAGE" {
  for_each         = var.orchestrated_repositories
  variable_name    = "PRIVATE_REPOSITORY_IMAGE"
  value            = "${var.config.repository_socket}/${var.config.repository_user}/${each.key}"
  repository       = each.key
}

#
resource "github_actions_variable" "LOCAL_CACHE_PATH" {
  for_each         = var.orchestrated_repositories
  variable_name    = "LOCAL_CACHE_PATH"
  value            = "/${var.config.cache_path}/${var.config.repository_user}/${each.key}"
  repository       = each.key
}

resource "github_actions_variable" "ARGO_APP_NAME" {
  for_each         = var.orchestrated_repositories
  variable_name    = "LOCAL_CACHE_PATH"
  value            = "${each.key}"
  repository       = each.key
}



##
##
##

locals {
  flattened_secrets = flatten([
    for nm, secret in var.secrets : [
      for repo in var.orchestrated_repositories : {
        secret_name = nm
        plaintext_value = secret
        repository = repo
      }
    ]
  ])

  flattened_variables = flatten([
    for nm, variable in var.variables : [
      for repo in var.orchestrated_repositories : {
        variable_name = nm
        value = variable
        repository = repo
      }
    ]
  ])
}

resource "github_actions_secret" "secrets" {
  for_each = {
    for obj in local.flattened_secrets :
    "${obj.secret_name}.${obj.repository}" => obj
  }
  secret_name       = each.value.secret_name
  plaintext_value   = each.value.plaintext_value
  repository        = each.value.repository
}

resource "github_actions_variable" "variables" {
  for_each = {
    for obj in local.flattened_variables :
    "${obj.variable_name}.${obj.repository}" => obj
  }

  variable_name    = each.value.variable_name
  value            = each.value.value
  repository       = each.value.repository
}
