mod "custom_ramblings" {
  # hub metadata
  title       = "Custom Ramblings"
  description = "Create dashboards and reports for your experiments using Steampipe."
  # color         = "#0089D6"
  # documentation = file("./docs/index.md")
  # icon          = "/images/mods/turbot/kubernetes-insights.svg"
  categories = ["zendesk", "dashboard"]

  opengraph {
    title       = "Steampipe Mod for Custom Experiments"
    description = "Total experiments for custom mods using Steampipe."
    # image        = "/images/mods/turbot/kubernetes-insights-social-graphic.png"
  }

  require {
    steampipe = "0.22.0"
    plugin "zendesk" {
      min_version = "0.8.0"
    }
  }

}
