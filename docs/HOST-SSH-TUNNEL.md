# Host-level Cloudflare Tunnel (SSH + deploy on master)

This runbook is for **`cloudflared` on the physical k3s master** so you can SSH and run deploys **without** exposing port 22 on your home router. It is **not** the same as the in-cluster tunnel managed by Terraform.

| Topic | Where it lives |
|--------|----------------|
| **HTTP apps** (sites in the cluster) | [terraform/modules/cloudflare-tunnel/main.tf](../terraform/modules/cloudflare-tunnel/main.tf), [CLOUDFLARE-TUNNEL-SETUP.md](./CLOUDFLARE-TUNNEL-SETUP.md) |
| **SSH to the master host** | This document + scripts below |

## Architecture

- **Connector**: `cloudflared` runs as **systemd** on the master OS (outside Kubernetes).
- **Tunnel**: Use a **separate** Cloudflare Tunnel and token from the one in `terraform/terraform.tfvars` (`cloudflare_tunnel_token`). Mixing tokens between the cluster pod connector and the host connector causes confusion and shared identity; keep SSH ops on its own tunnel.
- **Target**: Cloudflare forwards SSH to `ssh://127.0.0.1:22` on the machine running the connector.

## Master host (reference)

See [CLUSTER-INFO.md](./CLUSTER-INFO.md) and [scripts/cluster-hosts.env](../scripts/cluster-hosts.env). Default master: `ubuntu@192.168.7.200`.

Quick SSH from a machine on the LAN:

```bash
./scripts/cluster-management/ssh-nodes.sh master
```

## 1. Verify prerequisites (on the master)

From your laptop (if the master is reachable):

```bash
ssh ubuntu@192.168.7.200 'bash -s' < scripts/cluster-management/verify-master-tunnel-prereqs.sh
```

Or copy the script to the master and run it there. It checks: `sshd` active, TCP 22 listening, outbound HTTPS to Cloudflare, whether `cloudflared` is already installed, and `/home/ubuntu/.kube/config`.

**Last automated check (homelabs):** `sshd` active, `0.0.0.0:22` and `[::]:22` listening, Cloudflare HTTPS OK, **`cloudflared` not installed on host**, kubeconfig present.

## 2. Cloudflare Zero Trust: create tunnel and SSH route

Do this in the [Zero Trust dashboard](https://one.dash.cloudflare.com/) (manual; cannot be done from this repo).

1. Go to **Networks** → **Tunnels** → **Create a tunnel**.
2. Choose **Cloudflared**, name it (e.g. `homelabs-master-ssh`), **Save tunnel**.
3. **Public Hostnames** → **Add a public hostname**:
   - **Subdomain**: e.g. `ssh` (or `bastion`)
   - **Domain**: a zone on Cloudflare (must be proxied/DNS on Cloudflare)
   - **Service type**: **SSH**
   - **URL**: `ssh://localhost:22` (or `ssh://127.0.0.1:22`)
4. **Save hostname**.
5. Protect with **Zero Trust Access** (recommended): **Access** → **Applications** → add an application for that hostname so only your identity provider / allowed emails can open SSH. Follow Cloudflare’s SSH with Access guides for policy and login methods.
6. Copy the **tunnel token** shown for installing the connector (long `eyJ...` string). Store it in a password manager; **do not commit it to git**.

Official reference: [Connect to SSH with Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/use-cases/ssh/).

### Alternative: private network only

If you prefer not to use a public SSH hostname, you can use **private network routing** (WARP / tunnel routes to `192.168.7.0/24` or `/32`) per Cloudflare docs. SSH then behaves like VPN access; setup differs from the public hostname flow above.

## 3. Install connector on the master (systemd)

Copy [scripts/cluster-management/install-cloudflared-host-ssh.sh](../scripts/cluster-management/install-cloudflared-host-ssh.sh) to the master, then on the master:

```bash
chmod +x install-cloudflared-host-ssh.sh
sudo CLOUDFLARED_HOST_TUNNEL_TOKEN='YOUR_TOKEN_HERE' ./install-cloudflared-host-ssh.sh
```

The script installs the official `cloudflared` Debian package (if missing), runs `cloudflared service install <token>`, enables and starts `cloudflared.service`.

Check:

```bash
systemctl status cloudflared --no-pager
journalctl -u cloudflared -n 50 --no-pager
```

In the Zero Trust UI, the tunnel should show as **healthy** with an active connection.

## 4. Client configuration (other machines)

Install `cloudflared` on the client (e.g. `brew install cloudflare/cloudflare/cloudflared` on macOS).

With **Cloudflare Access** in front of SSH, typical OpenSSH config:

```ssh-config
Host homelabs-master-cf
  HostName ssh.example.com
  User ubuntu
  ProxyCommand cloudflared access ssh --hostname %h
```

Replace `ssh.example.com` with the hostname you configured on the tunnel. Authenticate per your Access policy (browser login or service token, per Cloudflare docs).

**Test from a network that cannot reach `192.168.7.200` directly** (e.g. mobile hotspot) to confirm traffic goes through Cloudflare.

## 5. Deploying this repo from the master

After you can SSH in (via tunnel or LAN):

1. Clone or update the repo, e.g. `git clone … ~/cluster` or `rsync` from your laptop.
2. **`kubectl`**: use `/home/ubuntu/.kube/config` (see [install-k3s-master.sh](../scripts/cluster-management/install-k3s-master.sh)) or `sudo kubectl` with k3s’s admin config.
3. **Terraform**: `terraform/terraform.tfvars` is gitignored. Copy from [terraform/terraform.tfvars.example](../terraform/terraform.tfvars.example) on the master and fill secrets, or export env vars as in [scripts/infrastructure/set-env-vars.sh](../scripts/infrastructure/set-env-vars.sh). Never commit tokens.

```bash
cd ~/cluster/terraform
export KUBECONFIG=/home/ubuntu/.kube/config
terraform init
terraform plan
terraform apply
```

**Remote `kubectl` from a laptop** without exposing the API on Cloudflare: after SSH works, use a local forward, e.g. `ssh -L 6443:127.0.0.1:6443 ubuntu@…` and point kubeconfig’s `server` to `https://127.0.0.1:6443` for that session (adjust if your kubeconfig uses the LAN IP only).

## Security notes

- Keep the **host tunnel token** as secret as the Terraform `cloudflare_tunnel_token`.
- Prefer **Access** policies on the SSH hostname over a wide-open SSH endpoint.
- You do not need to port-forward **TCP 22** on your home router if all admin SSH uses Cloudflare; you can still keep LAN SSH for maintenance.

## Troubleshooting

| Symptom | What to check |
|---------|----------------|
| Tunnel disconnected | `journalctl -u cloudflared -e` on master; token revoked or wrong tunnel |
| SSH hangs from internet | DNS CNAME/proxy for hostname; Access policy; client `cloudflared` version |
| “Works on LAN, not via CF” | Test with `ProxyCommand` / Access from off-LAN |
