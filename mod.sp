mod "custom_ramblings" {
  # hub metadata
  title         = "Custom Ramblings"
  description   = "Create dashboards and reports for your experiments using Steampipe."
  # color         = "#0089D6"
  # documentation = file("./docs/index.md")
  # icon          = "/images/mods/turbot/kubernetes-insights.svg"
  # categories    = ["kubernetes", "dashboard", "public cloud"]

  opengraph {
    title        = "Steampipe Mod for Custom Experiments"
    description  = "Total experiments for custom mods using Steampipe."
    # image        = "/images/mods/turbot/kubernetes-insights-social-graphic.png"
  }

  require {
    steampipe = "0.20.10"
    plugin "zendesk" {
      version = "0.6.0"
    }
  }

}
