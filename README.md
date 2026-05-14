# 🚀 Enterprise DevOps & SRE Automation Suite

[![CI](https://github.com/Alex-Agbey/devops-bash-scripts/actions/workflows/ci.yml/badge.svg)](https://github.com/Alex-Agbey/devops-bash-scripts/actions)
![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnu-bash&logoColor=white)
![ShellCheck](https://img.shields.io/badge/Linted-ShellCheck-blue)
![Tested](https://img.shields.io/badge/Tested-Bats-green)

A collection of production-ready DevOps automation bash scripts organized into 5 real-world categories. Every script follows industry best practices: **Strict Mode (`set -euo pipefail`)**, robust error handling, structured logging, and color-coded output.

---

## 🛠️ Infrastructure & Automation
All scripts are linted with **ShellCheck** and unit-tested with **Bats** (Bash Automated Testing System) to ensure reliability in production environments.

### 🖥️ system/ – Server Health & Management
| Script | Description |
| :--- | :--- |
| `health-check.sh` | Comprehensive CPU, Memory, Disk, and Service health report. |
| `disk-alert.sh` | Automated alerts when disk usage exceeds a defined threshold. |
| `user-setup.sh` | Secure user provisioning with SSH key injection and Sudoers config. |

### 🐳 docker/ – Container & Image Operations
| Script | Description |
| :--- | :--- |
| `cleanup.sh` | Aggressive cleanup of dangling images, exited containers, and unused volumes. |
| `backup-volumes.sh` | Compresses and archives named Docker volumes to `.tar.gz`. |
| `image-scan.sh` | Security-first: Scans Docker images for CVEs using **Trivy**. |

### ☸️ kubernetes/ – K8s Operations
| Script | Description |
| :--- | :--- |
| `pod-restarts.sh` | Identifies and alerts on unstable pods with high restart counts. |
| `namespace-cleanup.sh` | Safely removes all resources within a specific namespace. |
| `rolling-restart.sh` | Performs zero-downtime rolling restarts for deployments. |

### 📜 logs/ – Log Management
| Script | Description |
| :--- | :--- |
| `log-rotate.sh` | Automated compression and archiving of aging log files. |
| `log-search.sh` | High-speed contextual search across distributed log directories. |

### 🚢 deploy/ – CI/CD & Orchestration
| Script | Description |
| :--- | :--- |
| `env-check.sh` | Pre-flight validation of required environment variables. |
| `app-deploy.sh` | Full pipeline: Build, Registry Push (Docker Hub), and K8s Deployment. |
| `rollback.sh` | Instant recovery via Kubernetes deployment rollbacks. |

---

## 🚦 Getting Started
### Prerequisites
*   **ShellCheck:** `sudo apt install shellcheck`
*   **Trivy:** (For image scanning)
*   **Bats Core:** (For running tests)

### Running a script
Ensure the script is executable:
```bash
chmod +x ./system/health-check.sh
./system/health-check.sh
