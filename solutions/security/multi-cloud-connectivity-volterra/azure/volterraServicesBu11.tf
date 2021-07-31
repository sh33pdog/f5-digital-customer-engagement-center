resource "volterra_origin_pool" "bu11app" {
  name                   = "bu11app"
  namespace              = var.namespace
  endpoint_selection     = "DISTRIBUTED"
  loadbalancer_algorithm = "LB_OVERRIDE"
  port                   = 80
  no_tls                 = true

  origin_servers {
    private_ip {
      ip = module.webserver["bu11"].privateIp
      site_locator {
        site {
          tenant    = var.volterraTenant
          namespace = "system"
          name      = volterra_azure_vnet_site.bu11.name
        }
      }
      inside_network = true
    }

    labels = {
      "bu" = "bu11"
    }
  }
}

resource "volterra_http_loadbalancer" "bu11app" {
  name                            = "bu11app"
  namespace                       = var.namespace
  no_challenge                    = true
  domains                         = ["bu11app.shared.acme.com"]
  random                          = true
  disable_rate_limit              = true
  service_policies_from_namespace = true
  disable_waf                     = true

  advertise_custom {
    advertise_where {
      port = 80
      virtual_site {
        network = "SITE_NETWORK_INSIDE"
        virtual_site {
          name      = volterra_virtual_site.site.name
          namespace = volterra_virtual_site.site.namespace
          tenant    = var.volterraTenant
        }
      }
    }
  }

  default_route_pools {
    pool {
      name = volterra_origin_pool.bu11app.name
    }
  }

  http {
    dns_volterra_managed = false
  }
}
