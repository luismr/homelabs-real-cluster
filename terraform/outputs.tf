output "namespaces" {
  description = "The namespaces for each domain"
  value = {
    pudim_dev            = module.pudim_dev.namespace
    luismachadoreis_dev  = module.luismachadoreis_dev.namespace
    carimbo_vip          = module.carimbo_vip.namespace
    singularideas_com_br = module.singularideas_com_br.namespace
    leticiacarvalho_pro  = module.leticiacarvalho_pro.namespace
    brickfolio_online    = module.brickfolio_online.namespace
    brickfolio_qa        = module.brickfolio_qa.namespace
    brickfolio_prod      = module.brickfolio_prod.namespace
  }
}

output "pudim_dev" {
  description = "pudim.dev domain outputs"
  value = {
    namespace          = module.pudim_dev.namespace
    service            = module.pudim_dev.service_name
    redis_service      = module.pudim_dev.redis_service_name
    redis_url          = module.pudim_dev.redis_url
    url                = module.pudim_dev.site_url
    internal_url       = module.pudim_dev.internal_url
    internal_url_short = module.pudim_dev.internal_url_short
    redis              = module.pudim_dev.redis
    dynamodb           = module.pudim_dev.dynamodb
    leaderboard        = module.pudim_dev.leaderboard
  }
}

output "luismachadoreis_dev" {
  description = "luismachadoreis.dev domain outputs"
  value = {
    namespace                                   = module.luismachadoreis_dev.namespace
    service                                     = module.luismachadoreis_dev.service_name
    url                                         = module.luismachadoreis_dev.site_url
    internal_url                                = module.luismachadoreis_dev.internal_url
    internal_url_short                          = module.luismachadoreis_dev.internal_url_short
    mcp_blueprint_prompts_frontend_service      = module.luismachadoreis_dev.mcp_blueprint_prompts_frontend_service_name
    mcp_blueprint_prompts_frontend_deployment   = module.luismachadoreis_dev.mcp_blueprint_prompts_frontend_deployment_name
    mcp_blueprint_prompts_frontend_internal_url = module.luismachadoreis_dev.mcp_blueprint_prompts_frontend_internal_url
    mcp_blueprint_prompts_sse_service           = module.luismachadoreis_dev.mcp_blueprint_prompts_sse_service_name
    mcp_blueprint_prompts_sse_deployment        = module.luismachadoreis_dev.mcp_blueprint_prompts_sse_deployment_name
    mcp_blueprint_prompts_sse_internal_url      = module.luismachadoreis_dev.mcp_blueprint_prompts_sse_internal_url
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
    waha_service             = try(module.carimbo_vip.waha_service_name, null)
    waha_deployment          = try(module.carimbo_vip.waha_deployment_name, null)
    waha_url                 = try(module.carimbo_vip.waha_url, null)
    waha_internal_url        = try(module.carimbo_vip.waha_internal_url, null)
    waha_internal_url_short  = try(module.carimbo_vip.waha_internal_url_short, null)
    n8n_service              = try(module.carimbo_vip.n8n_service_name, null)
    n8n_deployment           = try(module.carimbo_vip.n8n_deployment_name, null)
    n8n_internal_url         = try(module.carimbo_vip.n8n_internal_url, null)
    n8n_internal_url_short   = try(module.carimbo_vip.n8n_internal_url_short, null)
    n8n_webhook_url          = try(module.carimbo_vip.n8n_webhook_url, null)
    n8n_host                 = try(module.carimbo_vip.n8n_host, null)
    n8n_webhook_full_url     = try(module.carimbo_vip.n8n_webhook_full_url, null)
  }
}

output "singularideas_com_br" {
  description = "singularideas.com.br domain outputs"
  value = {
    namespace                = module.singularideas_com_br.namespace
    service                  = module.singularideas_com_br.service_name
    url                      = module.singularideas_com_br.site_url
    internal_url             = module.singularideas_com_br.internal_url
    internal_url_short       = module.singularideas_com_br.internal_url_short
    forms_service            = try(module.singularideas_com_br.forms_service_name, null)
    forms_deployment         = try(module.singularideas_com_br.forms_deployment_name, null)
    forms_url                = try(module.singularideas_com_br.forms_url, null)
    forms_internal_url       = try(module.singularideas_com_br.forms_internal_url, null)
    forms_internal_url_short = try(module.singularideas_com_br.forms_internal_url_short, null)
    waha_service             = try(module.singularideas_com_br.waha_service_name, null)
    waha_deployment          = try(module.singularideas_com_br.waha_deployment_name, null)
    waha_url                 = try(module.singularideas_com_br.waha_url, null)
    waha_internal_url        = try(module.singularideas_com_br.waha_internal_url, null)
    waha_internal_url_short  = try(module.singularideas_com_br.waha_internal_url_short, null)
  }
}

output "leticiacarvalho_pro" {
  description = "leticiacarvalho.pro domain outputs"
  value = {
    namespace          = module.leticiacarvalho_pro.namespace
    service            = module.leticiacarvalho_pro.service_name
    url                = module.leticiacarvalho_pro.site_url
    internal_url       = module.leticiacarvalho_pro.internal_url
    internal_url_short = module.leticiacarvalho_pro.internal_url_short
  }
}

output "brickfolio_online" {
  description = "brickfolio.online domain outputs"
  value = {
    namespace                = module.brickfolio_online.namespace
    service                  = module.brickfolio_online.service_name
    url                      = module.brickfolio_online.site_url
    internal_url             = module.brickfolio_online.internal_url
    internal_url_short       = module.brickfolio_online.internal_url_short
    forms_service            = try(module.brickfolio_online.forms_service_name, null)
    forms_deployment         = try(module.brickfolio_online.forms_deployment_name, null)
    forms_url                = try(module.brickfolio_online.forms_url, null)
    forms_internal_url       = try(module.brickfolio_online.forms_internal_url, null)
    forms_internal_url_short = try(module.brickfolio_online.forms_internal_url_short, null)
  }
}

output "brickfolio_qa" {
  description = "brickfolio QA environment (brickfolio-online-qa) outputs"
  value = {
    namespace                           = module.brickfolio_qa.namespace
    api_service_name                    = module.brickfolio_qa.api_service_name
    app_service_name                    = module.brickfolio_qa.app_service_name
    api_url                             = module.brickfolio_qa.api_url
    app_url                             = module.brickfolio_qa.app_url
    api_internal_url                    = module.brickfolio_qa.api_internal_url
    app_internal_url                    = module.brickfolio_qa.app_internal_url
    redis_service_name                  = module.brickfolio_qa.redis_service_name
    postgres_service_name               = module.brickfolio_qa.postgres_service_name
    postgres_node_port                  = module.brickfolio_qa.postgres_node_port
    postgres_nodeport_service_name      = module.brickfolio_qa.postgres_nodeport_service_name
    postgres_external_connection_string = module.brickfolio_qa.postgres_external_connection_string
  }
}

output "brickfolio_prod" {
  description = "brickfolio PROD environment (brickfolio-online-prod) outputs"
  value = {
    namespace                           = module.brickfolio_prod.namespace
    api_service_name                    = module.brickfolio_prod.api_service_name
    app_service_name                    = module.brickfolio_prod.app_service_name
    api_url                             = module.brickfolio_prod.api_url
    app_url                             = module.brickfolio_prod.app_url
    api_internal_url                    = module.brickfolio_prod.api_internal_url
    app_internal_url                    = module.brickfolio_prod.app_internal_url
    redis_service_name                  = module.brickfolio_prod.redis_service_name
    postgres_service_name               = module.brickfolio_prod.postgres_service_name
    postgres_node_port                  = module.brickfolio_prod.postgres_node_port
    postgres_nodeport_service_name      = module.brickfolio_prod.postgres_nodeport_service_name
    postgres_external_connection_string = module.brickfolio_prod.postgres_external_connection_string
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
    pudim_dev            = module.pudim_dev.site_url
    luismachadoreis_dev  = module.luismachadoreis_dev.site_url
    carimbo_vip          = module.carimbo_vip.site_url
    singularideas_com_br = module.singularideas_com_br.site_url
    leticiacarvalho_pro  = module.leticiacarvalho_pro.site_url
    brickfolio_online    = module.brickfolio_online.site_url
    brickfolio_qa_app    = module.brickfolio_qa.app_url
    brickfolio_qa_api    = module.brickfolio_qa.api_url
    brickfolio_prod_app  = module.brickfolio_prod.app_url
    brickfolio_prod_api  = module.brickfolio_prod.api_url
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
      from = join(", ", rule.sources)
      to   = rule.target
      code = try(rule.code, 301)
    }
  ]
}

