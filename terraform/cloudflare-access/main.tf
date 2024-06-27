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

##
## GET DOMAINS TO SECURE
##

#
data "external" "filtered_ingresses_with_hosts" {
  program = ["${path.module}/get_filtered_ingresses.sh"]
}

locals {
  subdomains_to_secure = split(",", data.external.filtered_ingresses_with_hosts.result.hosts)
}

##
##
##

# define access group
resource "cloudflare_access_group" "org_members_group" {
  account_id = var.cloudflare_account_id
  name = join("", [var.whitelisted_mail_domain, " users"])

  include {
    email_domain = [var.whitelisted_mail_domain]
  }
}

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
  domain                    = each.key
  type                      = "self_hosted"
  allow_authenticate_via_warp = true
  policies = [cloudflare_access_policy.allow_all_org_members.id]
}


# ##
# ## CONFIGURE WARP
# ##

data "cloudflare_access_application" "warp" {
  account_id = var.cloudflare_account_id
  domain     = join("", [var.cloudflare_zero_trust_team_name, ".cloudflareaccess.com/warp"])
}

# CANNOT REUSE POLICY FOR APP LAUNCHER, must use depreciated "application_id"
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

# ##
# ## CONFIGURE APP LAUNCHER
# ##

data "cloudflare_access_application" "app_launcher" {
  account_id = var.cloudflare_account_id
  name       = "App Launcher"  # The name of your access application
}

# CANNOT REUSE POLICY FOR APP LAUNCHER, must use depreciated "application_id"
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
