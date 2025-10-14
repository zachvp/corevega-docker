# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This repository manages a Docker-based home server infrastructure running in rootless mode. Services include:
- **navidrome**: Music streaming server
- **airsonic-advanced**: Alternative music streaming server
- **pihole**: Network-level ad blocking
- **reverse-proxy**: NGINX reverse proxy with automatic SSL via acme-companion

All services use an external Docker network (`corevega-net`) and run under rootless Docker (user 1000).

## Architecture

### Rootless Docker Configuration

This setup runs Docker in rootless mode, which introduces port binding restrictions. The system uses:
- **docker-rootlesskit-fix.path**: Monitors `/usr/bin/docker` and `/usr/bin/rootlesskit` for changes
- **docker-rootlesskit-fix.service**: Automatically restores `cap_net_bind_service` capability after Docker updates
- Both files located in `system-files/etc/systemd/system/`

When Docker or rootlesskit binaries are updated, the systemd path unit triggers the service to:
1. Set capabilities: `setcap cap_net_bind_service=ep $(which rootlesskit)`
2. Restart user Docker service: `systemctl --user restart docker`

### Dependency Mount Pattern

Services that require external media (navidrome, airsonic-advanced) use a `dependency-mount` container to ensure host paths exist before the main service starts:
- Alpine container that checks for mount point availability via healthcheck
- Script at `dependency-mount/dependency-mount.sh` performs mount validation
- Main services use `depends_on` with `condition: service_healthy`
- Prevents containers from creating host paths when media isn't mounted

Key configuration in docker-compose files:
```yaml
volumes:
  - type: bind
    source: /media/zachvp/...
    target: /music
    read_only: true
    bind:
      create_host_path: false  # Critical: prevents auto-creation
```

### Reverse Proxy Setup

The reverse-proxy service uses:
- **nginxproxy/nginx-proxy**: Automatic virtual host configuration based on container environment variables
- **nginxproxy/acme-companion**: Automatic Let's Encrypt SSL certificate management
- Containers expose themselves by setting: `VIRTUAL_HOST`, `LETSENCRYPT_HOST`, `VIRTUAL_PORT`
- Uses rootless Docker socket: `/run/user/1000/docker.sock`

## Common Commands

### Managing Services

Start a service:
```bash
cd <service-directory>
docker compose up -d
```

Stop a service:
```bash
cd <service-directory>
docker compose down
```

View service logs:
```bash
docker logs <container-name>
# Examples: docker logs navidrome, docker logs reverse-proxy
```

### Network Management

The external network must exist before starting services:
```bash
docker network create corevega-net
```

List all containers on the network:
```bash
docker network inspect corevega-net
```

### Systemd Units

After modifying systemd files in `system-files/`:
```bash
sudo cp system-files/etc/systemd/system/* /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable docker-rootlesskit-fix.path
sudo systemctl start docker-rootlesskit-fix.path
```

Check status:
```bash
systemctl status docker-rootlesskit-fix.path
systemctl status docker-rootlesskit-fix.service
```

### Rootless Docker

Check rootlesskit capabilities:
```bash
getcap $(which rootlesskit)
```

Restart rootless Docker:
```bash
systemctl --user restart docker
```

## Service-Specific Notes

### Navidrome
- Config stored in `/srv/docker/navidrome`
- Music library: `/media/zachvp/SOL/music`
- Uses debug logging: `ND_LOGLEVEL: debug`
- DNS: `192.168.50.1`
- Exposed via reverse proxy on `corevega.net`

### Airsonic-Advanced
- LinuxServer.io image variant
- Config stored in `/srv/docker/airsonic`
- Direct port exposure: `8000:4040`, `8001:4041` (UPnP)
- DNS: `192.168.1.1`

### Pi-hole
- Admin password in docker-compose.yml (update in production)
- Direct DNS port binding: `53:53/tcp`, `53:53/udp`
- Web interface: `8010:80`
- Config: `/srv/docker/pihole`

### Reverse Proxy
- Persistent volumes: `certs`, `html`, `vhost`, `dhparam`
- ACME account: `/home/zachvp/.acme.sh`
- Email for Let's Encrypt: `vegaperk@gmail.com`
- `TRUST_DOWNSTREAM_PROXY: false` for security
