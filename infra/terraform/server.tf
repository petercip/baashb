# SSH key — uploaded to Hetzner and injected into the server at creation time.
# Your private key never leaves your machine.
resource "hcloud_ssh_key" "main" {
  name       = "baashb-${var.environment}"
  public_key = var.ssh_public_key
}

# Static IPv4 — created separately from the server so it survives a server rebuild.
# If you ever run `terraform destroy && terraform apply` to replace the server,
# this IP stays the same and your DNS records keep working.
resource "hcloud_primary_ip" "web_v4" {
  name          = "baashb-web-${var.environment}-v4"
  datacenter    = local.datacenter
  type          = "ipv4"
  assignee_type = "server"
  auto_delete   = false
}

# Static IPv6 — same rationale as IPv4.
resource "hcloud_primary_ip" "web_v6" {
  name          = "baashb-web-${var.environment}-v6"
  datacenter    = local.datacenter
  type          = "ipv6"
  assignee_type = "server"
  auto_delete   = false
}

resource "hcloud_server" "web" {
  name        = "baashb-${var.environment}"
  server_type = var.server_type
  image       = "ubuntu-24.04"
  location    = var.location

  # SSH key auth only — no root password
  ssh_keys = [hcloud_ssh_key.main.id]

  # Attach static IPs so the address is stable across rebuilds
  public_net {
    ipv4_enabled = true
    ipv4         = hcloud_primary_ip.web_v4.id
    ipv6_enabled = true
    ipv6         = hcloud_primary_ip.web_v6.id
  }

  firewall_ids = [hcloud_firewall.main.id]

  # Automated daily backups — adds 20% to server cost (~$1/mo on CX22).
  # Remove this line to disable if cost is a concern.
  backups = true

  labels = {
    environment = var.environment
    managed_by  = "terraform"
    app         = "baashb"
  }
}
