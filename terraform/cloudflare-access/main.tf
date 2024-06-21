# Configure the Cloudflare provider using the required_providers stanza
# required with Terraform 0.13 and beyond. You may optionally use version
# directive to prevent breaking changes occurring unannounced.
terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "kubernetes" {

}

data "kubernetes_namespaces" "all" {}

data "kubernetes_ingresses" "all" {
  for_each = data.kubernetes_namespaces.all.namespaces
  metadata {
    namespace = each.value.metadata[0].name
  }
}

locals {
  secure_ingresses = flatten([
    for ns_key, ns_value in data.kubernetes_ingresses.all : [
      for ingress in ns_value.items : ingress
      if contains(keys(ingress.metadata.annotations), "cloudflare-access/must-secure") && ingress.metadata.annotations["cloudflare-access/must-secure"] == "true"
    ]
  ])
  
  subdomains_to_secure = flatten([
    for ingress in local.secure_ingresses : [
      for rule in ingress.spec[0].rules : rule.host
    ]
  ])
}


resource "cloudflare_access_group" "org_members_group" {
  account_id = var.cloudflare_account_id
  name = "Org members"

  include {
    email_domain = [var.whitelisted_mail_domain]
  }
}

## CANNOT REUSE POLICY FOR WARP

data "cloudflare_access_application" "warp" {
  account_id = var.cloudflare_account_id
  domain     = join("", [var.cloudflare_zero_trust_team_name, ".cloudflareaccess.com/warp"])
}

resource "cloudflare_access_policy" "warp" {
  account_id     = var.cloudflare_account_id
  application_id = data.cloudflare_access_application.warp.id
  name           = "Allow All Orgs Members"
  precedence     = "1"
  decision       = "allow"

  include {
    group = [cloudflare_access_group.org_members_group.id]
  }
}

## CANNOT REUSE POLICY FOR APP LAUNCHER

data "cloudflare_access_application" "app_launcher" {
  account_id = var.cloudflare_account_id
  name       = "App Launcher"  # The name of your access application
}

resource "cloudflare_access_policy" "app_launcher" {
  account_id     = var.cloudflare_account_id
  application_id = data.cloudflare_access_application.app_launcher.id
  name           = "Allow All Orgs Members"
  precedence     = "1"
  decision       = "allow"

  include {
    group = [cloudflare_access_group.org_members_group.id]
  }
}

##

resource "cloudflare_access_policy" "allow_all_org_members" {
  account_id     = var.cloudflare_account_id
  name           = "Allow All Orgs Members"
  decision       = "allow"

  include {
    group = [cloudflare_access_group.org_members_group.id]
  }
}

resource "cloudflare_access_application" "apps" {
  for_each                  = toset(local.subdomains_to_secure)
  account_id                = var.cloudflare_account_id
  name                      = each.key
  domain                    = join(".", [each.key, var.whitelisted_mail_domain])
  type                      = "self_hosted"
  allow_authenticate_via_warp = true
  policies = [cloudflare_access_policy.allow_all_org_members.id]
}
