variable "gcp_oauth_accounts" {
  description = "A map of GCP OAuth service account identifiers, keyed by audience name."
  type = map(object({
    oauth = object({
      audience = string
      ids = object({
        authnz            = string
        axon_server       = string
        workspace_manager = string
        workflow_manager  = string
      })
    })
  }))
}
