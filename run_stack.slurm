#!/usr/bin/env bash
#SBATCH --job-name=branch-office
#SBATCH --partition=jupyter
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --time=08:00:00
#SBATCH --output=branch-office-%j.log
echo "================================================================"
echo " Starting Enterprise Branch Office Stack on $(hostname)"
echo " Job ID: ${SLURM_JOB_ID}"
echo " Start Time: $(date)"
echo "================================================================"
cd ~/projects/enterprise-branch-office
# Clean stale runtime PID locks only (keep image storage intact)
rm -rf /tmp/containers-run-* /tmp/events.log 2>/dev/null || true
# 1. Run bootstrap script
./bootstrap.sh
# 2. Give background services 20s to complete initialization
sleep 20
# 3. Run health check
./scripts/health-check.sh
echo "================================================================"
echo " Infrastructure stack is ACTIVE on $(hostname)"
echo " Access Nginx Web Portal at: http://$(hostname):8080/"
echo " To stop the stack, run: scancel ${SLURM_JOB_ID}"
echo "================================================================"
sleep infinity
