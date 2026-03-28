# Infrastructure — Hetzner Cloud

Terraform configuration for the baashb production server. Provisions a single
Hetzner CX22 VPS in Hillsboro, Oregon with a static IP, SSH-only firewall, and
automated daily backups. Deployment is handled by Kamal; this only manages the
underlying server and network.

## What Terraform manages

| Resource | Type |
|---|---|
| SSH key | `hcloud_ssh_key` |
| Static IPv4 + IPv6 | `hcloud_primary_ip` × 2 |
| Firewall (ports 22/80/443/ICMP) | `hcloud_firewall` |
| CX22 server | `hcloud_server` |

**Manual steps** (no Terraform support in Hetzner provider):
- Object Storage bucket — create in Hetzner Console (2 min, see Step 4 below)
- S3 credentials — account-level keys, created in Hetzner Console
- DNS records — add at your domain registrar

## State

`terraform.tfstate` is committed to this repo. It contains only resource IDs
and public IP addresses — no secrets. The API token is a provider variable and
is never written to state.

`terraform.tfvars` (your API token + SSH key) is gitignored. Never commit it.

---

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) ≥ 1.6
  ```bash
  brew install terraform        # macOS
  ```
- A Hetzner Cloud account at [console.hetzner.cloud](https://console.hetzner.cloud)
- An SSH key pair (`ssh-keygen -t ed25519` if you don't have one)

---

## First-time setup

### Step 1 — Create a Hetzner API token

1. Log in to [console.hetzner.cloud](https://console.hetzner.cloud)
2. Select your project (or create one named `baashb`)
3. **Security → API Tokens → Generate API Token**
4. Name: `terraform`, Permissions: **Read & Write**
5. Copy the token — you won't see it again

### Step 2 — Configure Terraform variables

```bash
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
hetzner_api_token = "your-token-here"
ssh_public_key    = "ssh-ed25519 AAAA..."   # cat ~/.ssh/id_ed25519.pub
```

Optional — restrict SSH to your IP (recommended):
```hcl
ssh_allowed_ips = ["203.0.113.42/32"]   # curl -s ifconfig.me
```

### Step 3 — Apply

```bash
terraform init     # downloads the Hetzner provider (~5 seconds)
terraform plan     # review what will be created (no changes made)
terraform apply    # type "yes" to create resources (~30 seconds)
```

Terraform prints a `next_steps` checklist after apply. Follow it.

### Step 4 — Create Object Storage bucket (Hetzner Console)

The Hetzner Terraform provider doesn't support bucket or S3 credential management,
so this is a one-time manual step:

1. **Hetzner Console → Object Storage → Create Bucket**
   - Name: `baashb-production`
   - Location: Hillsboro (same region as your server)
2. **Security → S3 Credentials → Generate Keys**
   - Copy the Access Key and Secret Key

### Step 5 — Update config/deploy.yml

Replace the placeholder server IP with Terraform's output:

```bash
terraform output kamal_server_entry
# → "  - 65.21.xxx.xxx"
```

Edit `config/deploy.yml`:
```yaml
servers:
  web:
    - 65.21.xxx.xxx   # ← paste the IP from terraform output
```

Also update the registry:
```yaml
registry:
  server: ghcr.io
  username: your-github-username
  password:
    - KAMAL_REGISTRY_PASSWORD
```

### Step 6 — Populate .kamal/secrets

```bash
# .kamal/secrets (gitignored)
RAILS_MASTER_KEY=$(cat config/master.key)
HETZNER_STORAGE_ACCESS_KEY_ID=<from step 4>
HETZNER_STORAGE_SECRET_ACCESS_KEY=<from step 4>
HETZNER_STORAGE_BUCKET=baashb-production
HETZNER_STORAGE_ENDPOINT=https://hil.your-objectstorage.com
KAMAL_REGISTRY_PASSWORD=<GitHub personal access token with write:packages scope>
```

### Step 7 — Update DNS

Add these records at your registrar (replace `65.21.xxx.xxx` with your IP):

```
A    baashb.com       65.21.xxx.xxx
A    *.baashb.com     65.21.xxx.xxx
```

Wait for propagation before running kamal setup (`dig baashb.com` should return your IP).

### Step 8 — First deploy

```bash
# From repo root
kamal setup      # SSH into server, install Docker, start Traefik, run db:prepare
kamal deploy     # build image, push to registry, deploy container
```

### Step 9 — Commit state

```bash
git add infra/terraform/terraform.tfstate
git commit -m "chore(infra): provision Hetzner production infrastructure"
git push origin dev
```

---

## Day-2 operations

### Deploy a new app version
```bash
# Triggered automatically on merge to master (once CI/CD is wired up).
# Or manually:
kamal deploy
```

### SSH into the server
```bash
kamal shell
# or directly:
ssh root@$(terraform output -raw server_ip)
```

### View app logs
```bash
kamal logs
```

### Scale up the server

Hetzner supports live resize for the same generation (CX22 → CX32 → CX42):

1. **Hetzner Console → Server → Resize** (or `hcloud server change-type`)
2. Update `server_type` in `terraform.tfvars`
3. Run `terraform apply` to reconcile state

### Modify firewall rules

Edit `firewall.tf`, then:
```bash
terraform plan    # review changes
terraform apply
```

### Tear down everything
```bash
terraform destroy   # destroys server + firewall + SSH key
                    # static IPs survive (auto_delete = false) — delete manually if wanted
```

---

## Security notes

- **API token** — stored in gitignored `terraform.tfvars` only. Use a dedicated
  project-scoped token (not your account token).
- **SSH port 22** — defaults to open. Set `ssh_allowed_ips` to your IP CIDR
  in `terraform.tfvars` for production hardening.
- **Root SSH access** — Kamal requires root (or a user with Docker access).
  The server has no password; SSH key only.
- **State file** — contains server IPs and resource IDs. Safe to commit.
  If you ever make the repo public, be aware the server IP is visible.
