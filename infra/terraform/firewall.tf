resource "hcloud_firewall" "main" {
  name = "baashb-${var.environment}"

  # HTTP — required for Let's Encrypt ACME challenges and HTTP→HTTPS redirects.
  # Traefik handles the redirect; do NOT block port 80 or cert renewal will fail.
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "80"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  # HTTPS — primary application traffic
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "443"
    source_ips = ["0.0.0.0/0", "::/0"]
  }

  # SSH — Kamal deploys over SSH. Restrict via ssh_allowed_ips in terraform.tfvars.
  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = var.ssh_allowed_ips
  }

  # ICMP — allows ping, traceroute, and path MTU discovery. Low risk, high utility.
  rule {
    direction  = "in"
    protocol   = "icmp"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}
