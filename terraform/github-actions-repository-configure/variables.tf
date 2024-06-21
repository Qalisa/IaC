variable "github_organization" {
  description = "GitHub org"
  type        = string
  sensitive   = false
}
variable "github_token" {
  description = "GitHub personal access token"
  type        = string
  sensitive   = true
}

variable "github_topic" {
  description = "GitHub topic to search"
  type        = string
  sensitive   = true
  default = "decorated"
}

#
#
#

variable "secrets" {
  description = "Map of secrets to set for each repository"
  type = map(string)
  default = {}
}

variable "config" {
  type = object({
    repository_socket = string 
    repository_user = string
    cache_path = string
  })
}

variable "variables" {
  description = "Map of variables to set for each repository"
  type = map(string)
  default = {}
}

