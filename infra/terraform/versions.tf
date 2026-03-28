terraform {
  required_version = ">= 1.6"

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.60"
    }
  }

  # State is stored locally and committed to the repo.
  # Safe for this project: Hetzner state contains only resource IDs and public IPs — no secrets.
  # The API token is a provider variable and is never written to state.
  #
  # To migrate to Terraform Cloud (recommended if CI/CD or multiple developers are added):
  #   1. Sign up at https://app.terraform.io (free tier supports 500 resources)
  #   2. Replace the above with:
  #        cloud {
  #          organization = "your-org"
  #          workspaces { name = "baashb-production" }
  #        }
  #   3. Run: terraform login && terraform init -migrate-state
}
