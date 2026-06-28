variable "services" {
  type = list(string)
  default = [
    "usrv-bio-track-users",
    "usrv-bio-track-garmin",
    "usrv-bio-track-connections",
    "usrv-bio-track-calendar",
    "usrv-bio-track-ai",
    "usrv-bio-track-training",
    "usrv-bio-track-health",
  ]
}
