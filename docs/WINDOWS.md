# Windows Installation

Golden Agents requires a bash shell. Windows users have several options.

## Option 1: WSL (Recommended)

```powershell
# Install WSL if not already installed
wsl --install

# Then from WSL bash:
git clone https://github.com/bordenet/golden-agents.git ~/.golden-agents
~/.golden-agents/generate-agents.sh --language=python --path=./my-project
```

## Option 2: Git Bash

1. Install [Git for Windows](https://git-scm.com/download/win) (includes Git Bash)
2. Open Git Bash
3. Run:

```bash
git clone https://github.com/bordenet/golden-agents.git ~/.golden-agents
~/.golden-agents/generate-agents.sh --language=python --path=./my-project
```

## Option 3: PowerShell Wrapper

The PowerShell wrapper auto-detects WSL or Git Bash:

```powershell
# Clone the repo
git clone https://github.com/bordenet/golden-agents.git $HOME\.golden-agents

# Use the PowerShell wrapper
~\.golden-agents\generate-agents.ps1 --language=python --path=.\my-project
```

The `.ps1` wrapper automatically uses WSL if available, falls back to Git Bash, or shows installation instructions if neither is found.

## Option 4: MSYS2 / Cygwin

Install [MSYS2](https://www.msys2.org/) or [Cygwin](https://www.cygwin.com/), then run from their bash shell.

## Requirements

- Bash 4.0+
- Git

