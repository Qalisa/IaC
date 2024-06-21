variable "cloudflare_api_token" {
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  type        = string
  sensitive   = true
}

##
##

variable "whitelisted_mail_domain" {
  type        = string
  sensitive   = false
}

variable "cloudflare_zero_trust_team_name" {
  type        = string
  sensitive   = false
}
