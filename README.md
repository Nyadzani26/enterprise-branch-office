# Enterprise Branch Office Infrastructure

A standalone, containerized Linux infrastructure stack built for a 50-person branch office. It runs internal collaboration, documentation, database, and monitoring services on a single enterprise Linux host, fully automated with a bootstrap script.

## The Problem

Branch offices typically face three major challenges. The first is internet dependency: when the WAN or local ISP drops, work stops if everything relies on cloud services. The second is SaaS costs, since paying per-user licensing for GitHub, Confluence, Datadog, and cloud databases gets expensive quickly for small branch sites. The third is data control — without solid internal tools, teams end up sharing files, drawings, and credentials over unmanaged channels. This setup keeps core services local on the LAN so the office stays fully operational regardless of external connectivity.

## Infrastructure Overview

The environment runs on Rocky Linux 8 / AlmaLinux using rootless Podman and Podman Compose. All services run on host networking behind an Nginx reverse proxy on port 8080.

### 1. Collaboration & Storage

Gitea, running on port 3004, is a lightweight self-hosted Git server used for internal code repositories and project tracking. Wiki.js, on port 3000, serves as the documentation platform for internal SOPs, runbooks, and team documentation, backed by MariaDB 10.11 on port 3306.

### 2. Monitoring & Logging

Prometheus, on port 9090, scrapes hardware and OS metrics every 15 seconds, with Node Exporter on port 9100 collecting host CPU, memory, disk I/O, and network stats. Grafana, on port 3002, acts as the central dashboard for viewing these metrics and logs. Loki (port 3100) and Promtail (port 9080) form the log collection and aggregation pipeline — Promtail tails logs and ships them to Loki, where they can be searched in Grafana. Uptime Kuma, on port 3001, functions as a heartbeat monitor and status page, checking all internal HTTP endpoints.

### 3. Traffic Routing

The Nginx reverse proxy on port 8080 acts as the single point of entry, routing requests by URL path (`/git/`, `/wiki/`, `/grafana/`, `/`) so users do not need to remember individual port numbers for each service.

## Key Technical Decisions

Everything runs under an unprivileged user using Podman and fuse-overlayfs, so no root daemon is required. Host networking is used to simplify communication between containers and host services without the overhead of a virtual bridge or NAT. Application databases and configurations live in `./data` on the host filesystem, which keeps the containers themselves stateless. Finally, a single bootstrap script automates environment checks, image pulling, directory creation, and service startup.

## Quick Start

This deployment requires an enterprise Linux distribution — Rocky Linux 8/9, AlmaLinux 8/9, or RHEL — along with Podman and Podman Compose installed.

To deploy, clone the repository and run the bootstrap script:

```bash
git clone https://github.com/Nyadzani26/enterprise-branch-office.git
cd enterprise-branch-office
./bootstrap.sh
```

Once running, services can be reached in a browser at `http://<server-ip>:8080/`. The root path serves the Uptime Kuma status dashboard, `/git/` serves Gitea for git repositories, `/wiki/` serves the Wiki.js knowledge base, and `/grafana/` serves the Grafana monitoring dashboard (default login `admin` / `admin`).

## Operations & Maintenance

To verify that all containers are running and HTTP endpoints are returning valid status codes, run `./scripts/health-check.sh`. To create a timestamped MariaDB dump and config archive, with automatic 7-day retention cleanup, run `./scripts/backup.sh`. To stop the services, run `podman-compose down`.

## Repository Structure

├── bootstrap.sh # Automated deployment script
├── docker-compose.yml # Service definitions
├── run_stack.slurm # Slurm batch job launcher (for HPC/cluster nodes)
├── .env.example # Credentials and configuration template
├── configs/
│ ├── nginx/conf.d/ # Reverse proxy route configuration
│ ├── prometheus/ # Metrics scrape configs
│ ├── loki/ # Log storage schema
│ └── promtail/ # Log scraper configuration
├── scripts/
│ ├── health-check.sh # Container and HTTP endpoint prober
│ └── backup.sh # Database dump and backup rotation
└── data/ # Persistent storage directories (git-ignored)


## Author

Gift Nyadzani — Systems & Infrastructure Engineer
