# Plex zeropoint module

This Terraform module deploys a Plex Media Server container using the Docker provider and the Zeropoint OS module pattern.

## Resources Created

- **Docker Image**: Pulls the official `plexinc/pms-docker:latest` image
- **Docker Container**: Plex server with optional hardware transcoding support

## Requirements

- Terraform >= 1.0
- Docker provider ~> 3.0
- Host GPU/driver support for hardware transcoding (optional):
  - NVIDIA: NVIDIA Container Runtime
  - Intel/AMD: VAAPI (`/dev/dri`) support

## Usage

### Via zeropoint API

Example install payload (replace `source` with your module location):

```bash
curl -X POST http://<zeropoint-node-name>:2370/modules/install \
  -H "Content-Type: application/json" \
  -d '{
    "source": "https://your-repo/plex-module.git", 
    "module_id": "plex",
    "arch": "arm64",
    "gpu_vendor": "nvidia"
  }'
```

### Manual (for testing)

Use the included VS Code run tasks or run the sequence below:

```bash
docker network create zpm-test-nw || echo 'Network already exists'
terraform init
terraform validate
terraform plan -var='zp_network_name=zpm-test-nw' -var='zp_module_storage=/workspaces/data' -out=tfplan
terraform apply -var='zp_network_name=zpm-test-nw' -var='zp_module_storage=/workspaces/data' -auto-approve
```

Then run the test script:

```bash
bash plex-test.sh
```

## Inputs

| Name | Type | Description | Default |
|------|------|-------------|---------|
| `zp_module_id` | string | Unique identifier for this module instance (injected by zeropoint) | `"plex"` |
| `zp_network_name` | string | Pre-created Docker network name (injected by zeropoint) | (required) |
| `zp_arch` | string | Target architecture: amd64, arm64, etc. (injected by zeropoint) | `"amd64"` |
| `zp_gpu_vendor` | string | GPU vendor: nvidia, amd, intel, or empty for no GPU (injected by zeropoint) | `""` |
| `zp_module_storage` | string | Host path for persistent storage (injected by zeropoint) | (required) |
| `plex_claim` | string | Optional Plex claim token to register the server | `""` |
| `tz` | string | Timezone for the container | `"UTC"` |

## Outputs

| Name | Description |
|------|-------------|
| `main` | Main Plex container resource (`docker_container`) |
| `plex_api_url` | URL for the Plex web UI accessible via Docker network |

## GPU / Hardware Transcoding

- **NVIDIA**: Module sets `runtime = "nvidia"` and `gpus = "all"` if `zp_gpu_vendor` is `nvidia`.
- **Intel/AMD (VAAPI)**: Module will map `/dev/dri` into the container when `zp_gpu_vendor` is non-empty and not `nvidia`.
- **No GPU**: Hardware options are left unset (CPU-only mode).

The host must have drivers installed and device nodes available; the module only maps devices and requests runtimes.

## Network & Service Discovery

- **Internal Port**: 32400 (Plex web UI/API)
- **Network**: Uses pre-created network provided by Zeropoint via `zp_network_name`
- **No Host Ports**: Service discovery is expected via Docker DNS; external exposure should be created through Zeropoint.

## Accessing Plex

### From Other Containers (Service Discovery)

Other containers on the same Docker network can reach Plex at:

```bash
curl http://plex-main:32400
```

### From Host (via Exposure)

External access requires creating an exposure through Zeropoint API or binding ports on the host (not recommended here).
