output "namespaces" {
  description = "The namespaces for each domain"
  value = {
    pudim_dev           = module.pudim_dev.namespace
    luismachadoreis_dev = module.luismachadoreis_dev.namespace
    carimbo_vip         = module.carimbo_vip.namespace
  }
}

output "pudim_dev" {
  description = "pudim.dev domain outputs"
  value = {
    namespace          = module.pudim_dev.namespace
    service            = module.pudim_dev.service_name
    url                = module.pudim_dev.site_url
    internal_url       = module.pudim_dev.internal_url
    internal_url_short = module.pudim_dev.internal_url_short
  }
}

output "luismachadoreis_dev" {
  description = "luismachadoreis.dev domain outputs"
  value = {
    namespace          = module.luismachadoreis_dev.namespace
    service            = module.luismachadoreis_dev.service_name
    url                = module.luismachadoreis_dev.site_url
    internal_url       = module.luismachadoreis_dev.internal_url
    internal_url_short = module.luismachadoreis_dev.internal_url_short
  }
}

output "carimbo_vip" {
  description = "carimbo.vip domain outputs"
  value = {
    namespace                = module.carimbo_vip.namespace
    service                  = module.carimbo_vip.service_name
    url                      = module.carimbo_vip.site_url
    internal_url             = module.carimbo_vip.internal_url
    internal_url_short       = module.carimbo_vip.internal_url_short
    forms_service            = try(module.carimbo_vip.forms_service_name, null)
    forms_deployment         = try(module.carimbo_vip.forms_deployment_name, null)
    forms_url                = try(module.carimbo_vip.forms_url, null)
    forms_internal_url       = try(module.carimbo_vip.forms_internal_url, null)
    forms_internal_url_short = try(module.carimbo_vip.forms_internal_url_short, null)
  }
}

output "cloudflare_tunnel_info" {
  description = "Cloudflare Tunnel deployment information (if enabled)"
  value = length(module.cloudflare_tunnel) > 0 ? {
    namespace = module.cloudflare_tunnel[0].namespace
    service   = module.cloudflare_tunnel[0].service_name
    } : {
    namespace = "N/A"
    service   = "Cloudflare Tunnel not deployed (token is empty)."
  }
}

output "sites_urls" {
  description = "URLs for all deployed sites"
  value = {
    pudim_dev           = module.pudim_dev.site_url
    luismachadoreis_dev = module.luismachadoreis_dev.site_url
    carimbo_vip         = module.carimbo_vip.site_url
  }
}

