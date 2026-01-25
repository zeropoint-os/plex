terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

variable "zp_module_id" {
  type        = string
  default     = "plex"
  description = "Unique identifier for this module instance (user-defined, freeform)"
}

 variable "zp_network_name" {
  type        = string
  description = "Pre-created Docker network name for this module (managed by zeropoint)"
}

variable "zp_arch" {
  type        = string
  default     = "amd64"
  description = "Target architecture - amd64, arm64, etc. (injected by zeropoint)"
}

variable "zp_gpu_vendor" {
  type        = string
  default     = ""
  description = "GPU vendor - nvidia, amd, intel, or empty for no GPU (injected by zeropoint)"
}

variable "zp_module_storage" {
  type        = string
  description = "Host path for persistent storage (injected by zeropoint)"
}

variable "plex_claim" {
  type        = string
  default     = ""
  description = "Optional Plex claim token to register the server"
}

variable "tz" {
  type        = string
  default     = "UTC"
  description = "Timezone for the container"
}

# Use official Plex image (pulled from registry)
resource "docker_image" "plex" {
  name         = "plexinc/pms-docker:latest"
  keep_locally = true
}

# Main Plex container (no host port binding)
resource "docker_container" "plex_main" {
  name  = "${var.zp_module_id}-main"
  image = docker_image.plex.image_id

  # Network configuration (provided by zeropoint)
  networks_advanced {
    name = var.zp_network_name
  }

  # Restart policy
  restart = "unless-stopped"

  # GPU access (NVIDIA uses runtime; others may need /dev/dri)
  runtime = var.zp_gpu_vendor == "nvidia" ? "nvidia" : null
  gpus    = var.zp_gpu_vendor != "" ? "all" : null

  # Environment variables (PLEX_CLAIM optional)
  env = [
    "PLEX_CLAIM=${var.plex_claim}",
    "TZ=${var.tz}",
  ]

  # Persistent storage for Plex
  volumes {
    host_path      = "${var.zp_module_storage}/config"
    container_path = "/config"
  }
  volumes {
    host_path      = "${var.zp_module_storage}/transcode"
    container_path = "/transcode"
  }
  volumes {
    host_path      = "${var.zp_module_storage}/media"
    container_path = "/data"
  }

  # Conditional device mapping for VAAPI (Intel/AMD)
  dynamic "devices" {
    for_each = var.zp_gpu_vendor != "" && var.zp_gpu_vendor != "nvidia" ? [1] : []
    content {
      host_path      = "/dev/dri"
      container_path = "/dev/dri"
      permissions    = "rwm"
    }
  }

  # No host port bindings; service discovery via Docker network
}

# Outputs for zeropoint (container resource only)
# Outputs for zeropoint (container resource only)
output "main" {
  value       = docker_container.plex_main
  description = "Main Plex container"
}

# Service ports for external access (defined but not bound to host)
# Service ports for external access (defined but not bound to host)
output "main_ports" {
  value = {
    web = {
      port        = 32400
      protocol    = "http"
      transport   = "tcp"
      description = "Plex Web UI/API"
      default     = true
    }
    dlna = {
      port        = 1900
      protocol    = "udp"
      transport   = "udp"
      description = "DLNA/UPnP discovery (optional)"
      default     = false
    }
  }
  description = "Service ports for external access"
}

# Plex API URL for easy consumption by other modules
output "plex_api_url" {
  value       = "http://${docker_container.plex_main.name}:32400"
  description = "Plex API URL accessible via Docker network"
}