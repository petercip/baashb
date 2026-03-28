# Infrastructure — Hetzner Cloud

Terraform configuration for the baash-b production server. Provisions a single
Hetzner cpx11 VPS in Hillsboro, Oregon with a static IP, SSH-only firewall, and
automated daily backups. Deployment is handled by Kamal; this only manages the
underlying server and network.

## What Terraform manages

| Resource | Type |
|---|---|
| SSH key | `hcloud_ssh_key` |
| Static IPv4 + IPv6 | `hcloud_primary_ip` × 2 |
| Firewall (ports 22/80/443/ICMP) | `hcloud_firewall` |
| cpx11 server | `hcloud_server` |
| DNS records (A + AAAA, apex + wildcard) | `dnsimple_zone_record` × 4 |

**Manual steps** (no Terraform support in relevant providers):
- Object Storage bucket — create in Hetzner Console (2 min, see Step 4 below)
- S3 credentials — account-level keys, created in Hetzner Console

## State

`terraform.tfstate` and `terraform.tfstate.backup` are **gitignored**. Keep
them locally; they contain your server IPs and resource IDs but no secrets.
If multiple operators need to manage infrastructure together, migrate to a
remote backend (Terraform Cloud, S3, etc.).

`terraform.tfvars` (your API tokens + SSH key) is also gitignored. Never commit it.

---

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) ≥ 1.6
  ```bash
  brew install terraform        # macOS
  ```
- A Hetzner Cloud account at [console.hetzner.cloud](https://console.hetzner.cloud)
- A DNSimple account with `baash-b.org` registered/transferred in
- An SSH key pair (`ssh-keygen -t ed25519` if you don't have one)

---

## First-time setup

### Step 1 — Create a Hetzner API token

1. Log in to [console.hetzner.cloud](https://console.hetzner.cloud)
2. Select your project (or create one named `baash-b`)
3. **Security → API Tokens → Generate API Token**
4. Name: `terraform`, Permissions: **Read & Write**
5. Copy the token — you won't see it again

### Step 2 — Get a DNSimple API token

1. Log in to [dnsimple.com](https://dnsimple.com)
2. **Account → Access Tokens → New Access Token**
   - Name: `terraform`
   - Copy the token — you won't see it again
3. Note your **account ID** — it's the number shown under your account name
   at [dnsimple.com/user](https://dnsimple.com/user), or in the URL when
   you navigate to a domain: `dnsimple.com/<account_id>/...`

### Step 3 — Configure Terraform variables

```bash
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
hetzner_api_token   = "your-hetzner-token-here"
ssh_public_key      = "ssh-ed25519 AAAA..."   # cat ~/.ssh/id_ed25519.pub
dnsimple_token      = "your-dnsimple-token-here"
dnsimple_account_id = "12345"                  # your numeric account ID
```

Optional — restrict SSH to your IP (recommended):
```hcl
ssh_allowed_ips = ["203.0.113.42/32"]   # curl -s ifconfig.me
```

### Step 4 — Apply

```bash
terraform init     # downloads the Hetzner + DNSimple providers (~5 seconds)
terraform plan     # review what will be created (no changes made)
terraform apply    # type "yes" to create resources + DNS records (~30 seconds)
```

Terraform prints a `next_steps` checklist after apply. Follow it.

### Step 5 — Create Object Storage bucket (Hetzner Console)

The Hetzner Terraform provider doesn't support bucket or S3 credential management,
so this is a one-time manual step:

1. **Hetzner Console → Object Storage → Create Bucket**
   - Name: `baash-b`
   - Location: Hillsboro (same region as your server)
2. **Security → S3 Credentials → Generate Keys**
   - Copy the Access Key and Secret Key

### Step 6 — Update config/deploy.yml

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

### Step 7 — Populate .kamal/secrets

```bash
# .kamal/secrets (gitignored — run from repo root)
RAILS_MASTER_KEY=$(cat config/master.key)
POSTGRES_PASSWORD=<strong random password>
BAASHB_DATABASE_PASSWORD=$POSTGRES_PASSWORD
HETZNER_STORAGE_ACCESS_KEY_ID=<from step 5>
HETZNER_STORAGE_SECRET_ACCESS_KEY=<from step 5>
HETZNER_STORAGE_BUCKET=baash-b
HETZNER_STORAGE_ENDPOINT=https://hil.your-objectstorage.com
KAMAL_REGISTRY_PASSWORD=<GitHub personal access token with write:packages scope>
```

### Step 8 — Wait for DNS propagation

DNS records were created by `terraform apply`. Check that they've propagated:

```bash
dig baash-b.org A @8.8.8.8 +short      # should return your server IP
dig baash-b.org AAAA @8.8.8.8 +short   # should return your server IPv6
```

DNS typically propagates within a few minutes via DNSimple's anycast network.

### Step 9 — First deploy

```bash
# From repo root
bin/kamal setup   # installs Docker on server, starts kamal-proxy, builds + pushes
                  # image, and runs db:prepare (creates the primary schema tables)
```

`kamal setup` does **not** create the Solid Queue, Solid Cache, or Solid Cable
tables — those live in separate named-connection schemas. Run this once after
`kamal setup` completes:

```bash
bin/kamal app exec "bin/rails db:schema:load:queue db:schema:load:cache db:schema:load:cable"
```

This loads `db/queue_schema.rb`, `db/cache_schema.rb`, and `db/cable_schema.rb`
into the production database. You only need to run this once — the tables
persist across subsequent deploys.

---

## CI/CD — GitHub Actions auto-deploy

Every push to `master` that passes all CI jobs (lint, test, system-test,
scan_ruby, scan_js) automatically deploys to production via `bin/kamal deploy`.

### GitHub Secrets required

Go to **GitHub → Settings → Secrets and variables → Actions → New repository secret**
and create each of the following:

| Secret | Value | How to get it |
|--------|-------|---------------|
| `SSH_PRIVATE_KEY` | Your SSH private key (full file contents) | `cat ~/.ssh/id_ed25519` — must be the key whose public key is authorized on the server |
| `SSH_KNOWN_HOSTS` | Server host key fingerprint | `ssh-keyscan -H 5.78.203.114` — run once, paste full output |
| `RAILS_MASTER_KEY` | Rails master key | `cat config/master.key` |
| `POSTGRES_PASSWORD` | Production postgres password | Same value as in your local `.kamal/secrets` |
| `HETZNER_STORAGE_ACCESS_KEY_ID` | Object storage access key | Hetzner Console → Security → S3 Credentials |
| `HETZNER_STORAGE_SECRET_ACCESS_KEY` | Object storage secret key | Same as above (shown once at creation) |
| `HETZNER_STORAGE_ENDPOINT` | Storage endpoint URL | e.g. `https://hil.your-objectstorage.com` |
| `HETZNER_STORAGE_BUCKET` | Bucket name | `baash-b` |

**Not needed as a secret:** `KAMAL_REGISTRY_PASSWORD` — the workflow uses
GitHub's built-in `GITHUB_TOKEN` (with `packages: write` permission) to
authenticate with `ghcr.io`. No manual PAT required.

**Not needed as a separate secret:** `BAASHB_DATABASE_PASSWORD` — the
workflow derives it from `POSTGRES_PASSWORD` when writing `.kamal/secrets`.

### How the deploy works

1. All CI jobs (lint/test/system-test/scan_ruby/scan_js) run in parallel.
2. If all pass, the `deploy` job starts.
3. It writes `.kamal/secrets` from the GitHub Secrets above.
4. It SSHes into the production server using `SSH_PRIVATE_KEY`.
5. It runs `bin/kamal deploy` — builds the Docker image, pushes to `ghcr.io`,
   and rolls it out to the server.

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
bin/kamal shell
# or directly:
ssh root@$(terraform output -raw server_ip)
```

### View app logs
```bash
bin/kamal logs
```

### Connect to the production database
The postgres container binds to `127.0.0.1:5432` on the server (not exposed
to the internet). Reach it via SSH tunnel:

```bash
ssh -L 5433:127.0.0.1:5432 root@5.78.203.114 -fN
psql -h localhost -p 5433 -U baashb -d baashb_production
# password is POSTGRES_PASSWORD from .kamal/secrets
```

Or use the Kamal alias:
```bash
bin/kamal dbc   # opens Rails dbconsole inside the app container
```

### Scale up the server

Hetzner supports live resize for the same generation (cpx11 → cpx21 → cpx31):

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
