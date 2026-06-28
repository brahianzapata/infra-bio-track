variable "cluster_name" {
  type = string
}

variable "aws_account_id" {
  type = string
}

variable "github_org" {
  type    = string
  default = "brahianzapata"
}

variable "microservice_repos" {
  type = list(string)
  default = [
    "usrv-bio-track-users", "usrv-bio-track-garmin", "usrv-bio-track-connections",
    "usrv-bio-track-calendar", "usrv-bio-track-ai", "usrv-bio-track-training",
    "usrv-bio-track-health",
  ]
}
