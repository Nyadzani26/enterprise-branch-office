# Enterprise Branch Office Infrastructure (Learning Project)

This is a project I built to learn how real infrastructure gets put together — containers, reverse proxies, monitoring, the works. The idea was to simulate what a small branch office (around 50 people) might actually need to run day-to-day: internal git hosting, a wiki, and monitoring, all self-hosted on a single Linux box instead of relying on cloud SaaS tools.

## Why I Built This

I wanted to understand a few things that are hard to really "get" without building them yourself:

- What happens when a small office can't depend on a stable internet connection for every tool it uses
- Why companies end up paying for things like GitHub, Confluence, or Datadog per user, and what it'd take to self-host alternatives
- How to keep infrastructure reasonably secure and organized without root access everywhere

So instead of just reading about it, I set out to build a working stack that keeps the core services running locally, on the LAN, regardless of what the internet connection is doing.

## What's Running

I used Rocky Linux 8 / AlmaLinux as the base, and ran everything through rootless Podman and Podman Compose, sitting behind an Nginx reverse proxy on port 8080. Here's what's in the stack:

**Collaboration & Storage**
- Gitea (port 3004) — a lightweight self-hosted Git server for internal repos
- Wiki.js (port 3000) — for documentation, SOPs, and notes
- MariaDB 10.11 (port 3306) — database backend for Wiki.js

**Monitoring & Logging**
- Prometheus (port 9090) — scrapes system metrics every 15 seconds
- Node Exporter (port 9100) — feeds Prometheus CPU, memory, disk, and network stats
- Grafana (port 3002) — dashboards for everything Prometheus and Loki collect
- Loki (port 3100) + Promtail (port 9080) — log aggregation pipeline
- Uptime Kuma (port 3001) — status page and heartbeat checks for all the internal services

**Traffic Routing**
- Nginx (port 8080) — single entry point that routes by path (`/git/`, `/wiki/`, `/grafana/`), so you don't need to remember a bunch of ports

## What I Learned / Decisions I Made

Going rootless with Podman and fuse-overlayfs was mostly a learning choice — no root daemon needed, which felt like a better habit to build than defaulting to Docker with root. I used host networking to keep things simple rather than fighting with bridge networks and NAT while I was still learning how containers talk to each other. Data lives in `./data` on the host so the containers themselves stay stateless — that way I can nuke and rebuild containers without losing anything. And I wrote a single bootstrap script to automate the whole setup, mostly because I got tired of manually redoing the same steps every time I broke something and had to start over.

## Quick Start

You'll need an enterprise Linux distro (Rocky Linux 8/9, AlmaLinux 8/9, or RHEL) with Podman and Podman Compose installed.

```bash
git clone https://github.com/Nyadzani26/enterprise-branch-office.git
cd enterprise-branch-office
./bootstrap.sh
```

Once it's up, everything's reachable through `http://<server-ip>:8080/`:

- `/` — Uptime Kuma status dashboard
- `/git/` — Gitea
- `/wiki/` — Wiki.js
- `/grafana/` — Grafana (default login: `admin` / `admin`)

## Maintenance

- `./scripts/health-check.sh` — checks all containers and endpoints are actually up
- `./scripts/backup.sh` — dumps MariaDB and configs, with 7-day retention cleanup
- `podman-compose down` — stops everything

## Repository Structure

​```
├── bootstrap.sh              # Automated deployment script
├── docker-compose.yml        # Service definitions
├── run_stack.slurm           # Slurm batch job launcher (for HPC/cluster nodes)
├── .env.example               # Credentials and configuration template
├── configs/
│   ├── nginx/conf.d/         # Reverse proxy route configuration
│   ├── prometheus/           # Metrics scrape configs
│   ├── loki/                 # Log storage schema
│   └── promtail/             # Log scraper configuration
├── scripts/
│   ├── health-check.sh       # Container and HTTP endpoint prober
│   └── backup.sh             # Database dump and backup rotation
└── data/                      # Persistent storage directories (git-ignored)
​```

## Author

Gift Nyadzani — Systems & Infrastructure Engineer
