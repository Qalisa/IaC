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
    token = var.github_token
}

#
#
#

data "github_actions_public_key" "repo" {
  for_each = var.orchestrated_repositories
  repository = each.key
}

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
}

resource "github_actions_secret" "secrets" {
 for_each = {
    for obj in local.flattened_secrets :
    "${obj.secret_name}.${obj.repository}" => obj
  }
  secret_name = each.value.secret_name
  plaintext_value = each.value.plaintext_value
  repository = each.value.repository
}
