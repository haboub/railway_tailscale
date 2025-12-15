# Railway Tailscale VPN

## Overview

Host personal VPN on Railway using Tailscale

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.app/new/template/uIBpGp?referralCode=androidquartz)

## How to deploy on Railway (userspace networking)

1. Generate an auth key in the Tailscale admin console ([Settings → Keys](https://login.tailscale.com/admin/settings/keys)). Ephemeral keys are supported.
2. Create a Railway service from this repo and set the variable `TAILSCALE_AUTHKEY` to your generated key.
3. Deploy. The container starts `tailscaled` in userspace mode (`--tun=userspace-networking`) and keeps an HTTP health endpoint running on `$PORT`.
4. Validate from a Railway shell:
   ```sh
   railway run sh
   tailscale --socket=/tmp/tailscaled.sock status
   tailscale --socket=/tmp/tailscaled.sock netcheck
   ```
5. Connect your device:
   ```sh
   tailscale up --login-server=https://login.tailscale.com  # adjust if you use a custom control plane
   ```

## More Info

[Tailscale](https://tailscale.com/)

[Tailscale Exit nodes](https://tailscale.com/kb/1103/exit-nodes/)

[Using Tailscale Auth Keys](https://tailscale.com/kb/1085/auth-keys/)
