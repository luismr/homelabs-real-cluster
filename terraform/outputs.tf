output "namespaces" {
  description = "The namespaces for each domain"
  value = {
    pudim_dev           = module.pudim_dev.namespace
    luismachadoreis_dev = module.luismachadoreis_dev.namespace
    carimbo_vip         = module.carimbo_vip.namespace
    ligflat_com_br      = module.ligflat_com_br.namespace
    singularideas_com_br = module.singularideas_com_br.namespace
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

output "ligflat_com_br" {
  description = "ligflat.com.br domain outputs"
  value = {
    namespace          = module.ligflat_com_br.namespace
    service            = module.ligflat_com_br.service_name
    url                = module.ligflat_com_br.site_url
    internal_url       = module.ligflat_com_br.internal_url
    internal_url_short = module.ligflat_com_br.internal_url_short
  }
}

output "singularideas_com_br" {
  description = "singularideas.com.br domain outputs"
  value = {
    namespace          = module.singularideas_com_br.namespace
    service            = module.singularideas_com_br.service_name
    url                = module.singularideas_com_br.site_url
    internal_url       = module.singularideas_com_br.internal_url
    internal_url_short = module.singularideas_com_br.internal_url_short
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
    ligflat_com_br      = module.ligflat_com_br.site_url
    singularideas_com_br = module.singularideas_com_br.site_url
  }
}

output "redirects" {
  description = "All redirect rules configured in nginx-redirector"
  value = {
    namespace = module.redirects.namespace
    service   = module.redirects.service_name
    rules     = module.redirects.rules
  }
}

output "redirects_summary" {
  description = "Summary of all redirects in a readable format"
  value = [
    for rule in module.redirects.rules : {
      from   = join(", ", rule.sources)
      to     = rule.target
      code   = try(rule.code, 301)
    }
  ]
}

