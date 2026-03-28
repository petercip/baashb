output "server_ip" {
  value       = hcloud_primary_ip.web_v4.ip_address
  description = "Server IPv4 — add as A record for baash-b.org and *.baash-b.org."
}

output "server_ipv6" {
  value       = hcloud_primary_ip.web_v6.ip_address
  description = "Server IPv6 — add as AAAA record for baash-b.org and *.baash-b.org."
}

output "server_name" {
  value       = hcloud_server.web.name
  description = "Server name in Hetzner Console."
}

output "kamal_server_entry" {
  value       = "  - ${hcloud_primary_ip.web_v4.ip_address}"
  description = "Paste under servers.web in config/deploy.yml (replaces the 192.168.0.1 placeholder)."
}

output "hetzner_storage_endpoint" {
  value       = "https://${var.location}.your-objectstorage.com"
  description = "Set as HETZNER_STORAGE_ENDPOINT in .kamal/secrets."
}

output "next_steps" {
  value = <<-EOT

    ── Infrastructure ready. Next steps ──────────────────────────────────────────

    1. UPDATE config/deploy.yml
       Under servers.web, replace the 192.168.0.1 placeholder with:
         - ${hcloud_primary_ip.web_v4.ip_address}
       Update registry.server: localhost:5555 → ghcr.io
       Set registry.username to your GitHub username

    2. CREATE OBJECT STORAGE BUCKET (Hetzner Console — ~2 min)
       a. Object Storage → Create Bucket
          Name: baashb-production   Location: ${var.location}
       b. Security → S3 Credentials → Generate Keys
          Copy the Access Key and Secret Key

    3. POPULATE .kamal/secrets
       HETZNER_STORAGE_ACCESS_KEY_ID=<access key from step 2b>
       HETZNER_STORAGE_SECRET_ACCESS_KEY=<secret key from step 2b>
       HETZNER_STORAGE_BUCKET=baashb-production
       HETZNER_STORAGE_ENDPOINT=https://${var.location}.your-objectstorage.com
       RAILS_MASTER_KEY=$(cat config/master.key)

    4. DNS — already managed by Terraform (DNSimple)
       Records created by this apply:
         A    baash-b.org     → ${hcloud_primary_ip.web_v4.ip_address}
         A    *.baash-b.org   → ${hcloud_primary_ip.web_v4.ip_address}
         AAAA baash-b.org     → ${hcloud_primary_ip.web_v6.ip_address}
         AAAA *.baash-b.org   → ${hcloud_primary_ip.web_v6.ip_address}
       Wait for DNS propagation before running kamal setup.
       Check: dig baash-b.org A @8.8.8.8 +short

    5. FIRST DEPLOY
       kamal setup     # installs Docker on server, starts Traefik, runs db:prepare
       kamal deploy    # all subsequent deploys

    6. COMMIT STATE
       git add infra/terraform/terraform.tfstate
       git commit -m "chore(infra): provision Hetzner production infrastructure"

    ──────────────────────────────────────────────────────────────────────────────
  EOT
  description = "Post-apply checklist printed after every apply."
}
