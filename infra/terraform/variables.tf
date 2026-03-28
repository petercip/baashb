variable "hetzner_api_token" {
  type        = string
  sensitive   = true
  description = "Hetzner Cloud API token (Read & Write). Generate at: Hetzner Console → Project → Security → API Tokens → Generate API Token."
}

variable "ssh_public_key" {
  type        = string
  description = "Contents of your SSH public key (e.g. ~/.ssh/id_ed25519.pub). Run: cat ~/.ssh/id_ed25519.pub. The private key never touches Terraform or state."
}

variable "location" {
  type        = string
  default     = "hil"
  description = "Hetzner datacenter location. Options: hil (Hillsboro OR), ash (Ashburn VA), fsn1 (Falkenstein DE), nbg1 (Nuremberg DE), hel1 (Helsinki FI)."
}

variable "server_type" {
  type        = string
  default     = "cpx11"
  description = "Hetzner server type. cpx11 = 2 vCPU / 2 GB RAM / 40 GB disk (available in hil). Upgrade to cpx21 (3 vCPU / 4 GB) when needed."
}

variable "ssh_allowed_ips" {
  type        = list(string)
  default     = ["0.0.0.0/0", "::/0"]
  description = <<-EOT
    CIDRs allowed to reach SSH (port 22). Default allows all IPs.
    Restrict to your IP for better security, e.g.:
      ssh_allowed_ips = ["203.0.113.42/32"]
    Find your current IP: curl -s ifconfig.me
    Note: GitHub Actions IPs are dynamic — if CI needs SSH access, keep the default
    or add a bastion host instead of allowlisting the entire Actions IP range.
  EOT
}

variable "environment" {
  type        = string
  default     = "production"
  description = "Environment label — used as a suffix on resource names."
}
