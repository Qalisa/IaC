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


# Récupération des dépôts de l'organisation
data "github_repositories" "org_repos" {
  query = "org:${var.github_organization} topic:${var.github_topic}"
}

data "github_repository" "orchestrated_repositories" {
  for_each = toset(data.github_repositories.org_repos.names)
  name     = each.key
}

#
#
#

## REQUIRED
data "github_actions_public_key" "repos" {
  for_each = data.github_repository.orchestrated_repositories
  repository = each.key
}

#
resource "github_actions_variable" "PRIVATE_REPOSITORY_IMAGE" {
  for_each         = data.github_repository.orchestrated_repositories
  variable_name    = "PRIVATE_REPOSITORY_IMAGE"
  value            = "${var.config.repository_socket}/${var.config.repository_user}/${each.key}"
  repository       = each.key
}

#
resource "github_actions_variable" "LOCAL_CACHE_PATH" {
  for_each         = data.github_repository.orchestrated_repositories
  variable_name    = "LOCAL_CACHE_PATH"
  value            = "${var.config.cache_path}/${var.config.repository_user}/${each.key}"
  repository       = each.key
}

resource "github_actions_variable" "ARGO_APP_NAME" {
  for_each         = data.github_repository.orchestrated_repositories
  variable_name    = "ARGO_APP_NAME"
  value            = "${each.key}"
  repository       = each.key
}



##
##
##

locals {
  flattened_secrets = flatten([
    for nm, secret in var.secrets : [
      for repo in data.github_repository.orchestrated_repositories : {
        secret_name = nm
        plaintext_value = secret
        repository = repo.name
      }
    ]
  ])

  flattened_variables = flatten([
    for nm, variable in var.variables : [
      for repo in data.github_repository.orchestrated_repositories : {
        variable_name = nm
        value = variable
        repository = repo.name
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
