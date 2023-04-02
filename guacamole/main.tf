terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

# Create guacamole droplet
# REPLACE the ssh_keys with yours
resource "digitalocean_droplet" "guacvm" {
  image     = "ubuntu-22-10-x64"
  name      = "guacvm"
  region    = "fra1"
  size      = "s-2vcpu-2gb-intel"
  ssh_keys  = [XXXXX]
  user_data = file("${path.module}/guacamole.yml")
}

# create and assign a reserved ip to the droplet
resource "digitalocean_reserved_ip" "guacvm" {
  droplet_id = digitalocean_droplet.guacvm.id
  region     = digitalocean_droplet.guacvm.region
}
