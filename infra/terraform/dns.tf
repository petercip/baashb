# DNS records managed via DNSimple.
# Requires: dnsimple_token + dnsimple_account_id in terraform.tfvars.
#
# Records created:
#   A    baash-b.org     → server IPv4  (apex)
#   A    *.baash-b.org   → server IPv4  (wildcard subdomains / club custom domains via Traefik)
#   AAAA baash-b.org     → server IPv6  (apex)
#   AAAA *.baash-b.org   → server IPv6  (wildcard subdomains)

provider "dnsimple" {
  token   = var.dnsimple_token
  account = var.dnsimple_account_id
}

resource "dnsimple_zone_record" "root_a" {
  zone_name = "baash-b.org"
  name      = ""
  value     = hcloud_primary_ip.web_v4.ip_address
  type      = "A"
  ttl       = 3600
}

resource "dnsimple_zone_record" "wildcard_a" {
  zone_name = "baash-b.org"
  name      = "*"
  value     = hcloud_primary_ip.web_v4.ip_address
  type      = "A"
  ttl       = 3600
}

resource "dnsimple_zone_record" "root_aaaa" {
  zone_name = "baash-b.org"
  name      = ""
  value     = hcloud_primary_ip.web_v6.ip_address
  type      = "AAAA"
  ttl       = 3600
}

resource "dnsimple_zone_record" "wildcard_aaaa" {
  zone_name = "baash-b.org"
  name      = "*"
  value     = hcloud_primary_ip.web_v6.ip_address
  type      = "AAAA"
  ttl       = 3600
}
