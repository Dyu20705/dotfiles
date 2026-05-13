# Infrastructure & System Engineering Workflows

This guide covers workflows optimized for DevOps, SRE, and infrastructure engineers using this dotfiles setup.

## Kubernetes Operations

### Dashboard Management

```bash
# Launch K9s (Kubernetes TUI dashboard)
k9s

# Key commands in K9s
:ns              # Switch namespace
:po              # View pods
:dep             # View deployments
:svc             # View services
d                # Describe resource
e                # Edit resource
l                # Logs
```

### Kubectl Integration

```bash
# In Neovim with YAML files
nvim deployment.yaml          # Full LSP + formatting support
nvim service.yaml
nvim configmap.yaml

# Git diff for manifests
git diff deployment.yaml      # Shows diff via delta
```

### Kustomize/Helm

```bash
# Edit kustomization files
nvim kustomization.yaml
nvim values.yaml              # Helm charts
```

## Docker Management

### Container Operations

```bash
# Lazydocker TUI
lazydocker

# Key commands
i                 # Inspect container
l                 # View logs
e                 # Execute shell in container
s                 # Stop container
r                 # Restart container
```

### Dockerfile Development

```bash
# Full LSP support in Neovim
nvim Dockerfile

# Linting
nvim +Lint                    # Via nvim-lint
```

## Terraform & Infrastructure-as-Code

### Terraform Workflows

```bash
# Full Terraform LSP support
nvim main.tf
nvim variables.tf
nvim outputs.tf

# Inside Neovim
:!terraform fmt               # Format
:!terraform validate          # Validate
:!terraform plan              # Plan
```

### State Management

```bash
# Monitor state files
ncdu terraform/               # Analyze directory size
git diff terraform.tfstate    # State changes (delta formatting)
```

## Ansible Configuration Management

```bash
# Edit playbooks with full YAML LSP
nvim playbooks/site.yml
nvim group_vars/all.yml

# Linting (if yamllint installed)
:Lint
```

## SSH & Remote Access

### SSH Configuration

```bash
# Managed via infra/ssh/
cat ~/.config/dotfiles/infra/ssh/config

# Usage:
ssh my-server              # Connects via configured host
ssh k8s-master             # With multiplexing
```

### SSH Agent

```bash
# Add keys
ssh-add ~/.ssh/id_ed25519

# List keys
ssh-add -l

# Use with multiplexing
ssh -o ControlMaster=yes my-server
```

## Network Debugging

### DNS Operations

```bash
# Modern DNS tool (doggo)
doggo example.com A
doggo api.example.com MX

# Traditional dig
dig example.com
nslookup example.com
```

### HTTP Debugging

```bash
# Modern HTTP client (xh)
xh GET https://api.example.com/health
xh POST https://api.example.com/deploy token:abc123

# With authentication
xh --auth user:pass GET https://api.example.com
```

### Network Monitoring

```bash
# Packet capture
tcpdump -i eth0 -n port 8080
tcpdump -i eth0 "tcp port 443"

# Live bandwidth monitoring
bandwhich

# Network analysis
ss -tulpn              # Socket statistics
netstat -an            # Network stats
```

## System Performance Analysis

### CPU & Memory Profiling

```bash
# System monitor (btop - better than top)
btop

# CPU profiling
perf record ./my-app
perf report

# Per-process memory
ps aux --sort=-%mem

# Memory leaks
valgrind ./my-app
```

### I/O & Disk Analysis

```bash
# Disk usage (ncdu - interactive)
ncdu ~/                    # Interactive analyzer
ncdu -h -x ~/              # Human readable, same filesystem

# Modern du alternative
dust ~/                    # Simplified view

# I/O profiling
iotop -o                   # Only processes with I/O
iotop -p PID               # Specific process

# Disk I/O stats
iostat -x 1                # Device I/O statistics
```

### System Tracing

```bash
# Trace system calls
strace -e trace=network ./my-app
strace -e trace=file ./my-app
strace -o output.txt ./my-app

# Trace library calls
ltrace ./my-app

# Detailed timing
time -v ./my-app
```

## Performance Benchmarking

### Command Benchmarking

```bash
# Compare two implementations
hyperfine './solution-1.sh' './solution-2.sh'

# With multiple runs
hyperfine --runs 10 './solution-1.sh' './solution-2.sh'

# Export results
hyperfine --export-json results.json './solution-1.sh' './solution-2.sh'
```

### Application Benchmarking

```bash
# Shell startup performance
time zsh -i -c exit
for i in {1..10}; do time zsh -i -c exit; done

# Neovim startup
time nvim +q
nvim --startuptime /tmp/startup.log +q
tail -30 /tmp/startup.log
```

## Logging & Monitoring

### System Logs

```bash
# Journal logs (systemd)
journalctl -u service-name      # Service logs
journalctl -f                   # Follow logs
journalctl --since "1 hour ago" # Time range

# Kernel logs
dmesg
dmesg | tail -50

# Syslog
tail -f /var/log/syslog
```

### Application Logs

```bash
# Monitoring logs in Neovim
nvim /var/log/app.log

# Tail logs
tail -f app.log
tail -n 100 app.log | less
```

### Log Analysis

```bash
# Search logs
grep "ERROR" /var/log/app.log
grep -i "connection refused" /var/log/app.log

# Pattern matching
grep -E "ERROR|WARNING|FATAL" /var/log/app.log

# With context
grep -B 2 -A 2 "ERROR" /var/log/app.log
```

## Git Workflows for Infrastructure

### Branch Management

```bash
# Interactive git UI
lazygit

# Worktrees for parallel work
git worktree add ../feature-branch
cd ../feature-branch
git commit -m "Feature"
cd -
git worktree remove ../feature-branch
```

### Signed Commits

```bash
# Configured in .gitconfig to auto-sign
git commit -m "Deploy: k8s v1.28"  # Automatically signed

# Sign existing commit
git commit --amend -S
```

### Beautiful Diffs

```bash
# Configured in .gitconfig to use delta
git diff                           # Shows via delta
git log -p                         # Diffs in history
git show COMMIT                    # Diff for commit

# Side-by-side diffs
git diff --side-by-side
```

### Interactive Rebase

```bash
# Reorder, squash, drop commits
git rebase -i HEAD~5

# Commands:
# p pick
# r reword
# s squash
# f fixup
# d drop

# Resolve conflicts
git diff                           # Review conflicts
git add .
git rebase --continue
```

## Infrastructure Testing

### Kubernetes Testing

```bash
# Test deployments
kubectl apply -f deployment.yaml --dry-run=client

# Validate manifests
kubectl apply -f deployment.yaml --dry-run=server

# Debug pods
kubectl exec -it POD -- /bin/sh
kubectl logs POD
kubectl describe pod POD
```

### Docker Testing

```bash
# Build and test
docker build -t my-image .
docker run --rm -it my-image /bin/sh

# Inspect layers
docker history my-image
```

### Terraform Testing

```bash
# Validate
terraform validate

# Format check
terraform fmt -check

# Plan to file
terraform plan -out tfplan

# Apply from file
terraform apply tfplan
```

## Security Operations

### SSL/TLS Debugging

```bash
# Check certificate
openssl s_client -connect example.com:443

# Certificate details
openssl x509 -in cert.pem -text -noout

# Verify certificate chain
openssl verify cert.pem
```

### Secret Management

```bash
# Age encryption (if setup)
age -r KEY file.txt > file.txt.age
age -d -i KEY_FILE file.txt.age > file.txt

# GPG signing
gpg --sign file.txt
gpg --verify file.txt.gpg
```

## Automation & Scripting

### Shell Scripts

```bash
# Template scripts in scripts/setup/
cat scripts/setup/install-nvim.sh

# Make executable
chmod +x script.sh

# Profile script
bash -x script.sh                  # Debug mode
time script.sh                     # Timing
```

### Quick Task Running

```bash
# Using 'just' task runner
cat justfile

# Run tasks
just build
just deploy
just test
```

## Daily Workflows

### 1. Morning Standup

```bash
# System health check
fastfetch                          # System info
btop                               # Performance
k9s                                # Cluster status
```

### 2. Deploy Changes

```bash
# Review changes
lazygit                            # Git UI
git diff deployment.yaml           # With delta
terraform plan -out tfplan         # Infrastructure

# Deploy
kubectl apply -f deployment.yaml
terraform apply tfplan

# Monitor
k9s                                # Pods
kubectl logs -f POD                # Logs
btop                               # Performance
```

### 3. Troubleshoot Issues

```bash
# Collect data
kubectl describe pod POD_NAME
kubectl logs POD_NAME --previous
strace -f -e trace=network POD_COMMAND

# Analyze
ncdu -x /var/log                   # Disk usage
iotop -o                           # I/O hogs
bandwhich                          # Network
```

### 4. Performance Tuning

```bash
# Profile
perf record ./app
perf report

# Benchmark
hyperfine './old-impl' './new-impl'

# Monitor
btop
iotop -o
netstat -an | grep ESTABLISHED | wc -l
```

## Integration with Dotfiles

All tools are pre-configured with:
- **Shell aliases** for quick access
- **Neovim LSP** for config editing
- **Git** for version control
- **Documentation** in docs/

### Key Aliases (from shell config)

```bash
k='kubectl'              # Kubernetes
d='docker'               # Docker
tf='terraform'           # Terraform
az='az'                  # Azure CLI
git='git'                # Git (signed commits)

# Find these in: shell/zsh/aliases.zsh
```

### Key Keybindings (from Neovim)

```
<Leader>fg             # Find in files (Telescope)
<Leader>fh             # Help tags
:TroubleToggle         # Diagnostics
:NeotreeToggle         # File tree
K                      # Hover (LSP)
gd                     # Go to definition
gr                     # Go to references
<Leader>ca             # Code actions
```

## Advanced Topics

### CI/CD Integration

See `scripts/setup/` for automation-friendly scripts:
- Idempotent (safe to re-run)
- CI/CD compatible
- Error handling
- Validation

### Monitoring Stack

```
btop (system)
├─ CPU
├─ Memory
├─ Disk
└─ Network

Logs:
├─ journalctl (systemd)
├─ /var/log/
└─ application logs

Metrics:
├─ perf (profiling)
├─ iotop (I/O)
└─ hyperfine (benchmarks)
```

### Remote Work

```bash
# SSH with multiplexing
ssh -o ControlMaster=yes host

# Tmux over SSH
ssh -t host tmux attach -t work

# WireGuard/Tailscale
tailscale up
ssh tailscale-host
```

## Resources

- [Kubernetes Docs](https://kubernetes.io/docs/)
- [Terraform Docs](https://www.terraform.io/docs/)
- [Docker Docs](https://docs.docker.com/)
- [Git Docs](https://git-scm.com/doc)
- [Neovim LSP](https://neovim.io/doc/user/lsp.html)
