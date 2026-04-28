# Bidirectional Sync Script (Controlled Flow with rsync)

## Overview

This script provides a **controlled, production-friendly synchronization strategy** between a local machine and a remote server.

Instead of attempting a fully bidirectional sync (which is complex and error-prone), it applies **clear ownership rules**:

* **Code and project files** → managed locally and pushed to the remote server
* **Runtime data (logs, outputs, etc.)** → generated remotely and pulled back to local

This approach avoids conflicts, data loss, and unnecessary complexity.

---

## Synchronization Rules

### 1. Local → Remote (Project Files)

* Sends all project files from local to remote
* Removes files on the remote that were deleted locally
* **Excludes runtime directories**:

  * `data/`
  * `logs/`
  * `outputs/`

### 2. Remote → Local (Runtime Data)

* Synchronizes only specific directories from remote to local:

  * `data/`
  * `logs/`
  * `outputs/`
* These directories are treated as **remote-owned**

---

## Directory Flow

```
Local Project Root  ───────────────▶ Remote Project Root
      ▲                                   │
      │                                   │
      └──── data / logs / outputs ◀───────┘
```

---

## Requirements

* Linux or WSL environment
* `rsync` installed on both local and remote
* SSH access with key authentication
* Proper permissions on remote directories

---

## Configuration

Update the following variables in the script:

```bash
USER="ubuntu"
HOST="your.server.ip"
KEY="$HOME/.ssh/your-key"

LOCAL_BASE="/path/to/local/project"
REMOTE_BASE="/path/to/remote/project"
```

---

## Usage

Make the script executable:

```bash
chmod +x sync.sh
```

Run the script:

```bash
./sync.sh
```

---

## What the Script Does

### Step 1 — Local → Remote

```bash
rsync -avz --delete \
--exclude "data/" \
--exclude "logs/" \
--exclude "outputs/" \
...
```

* Syncs project files
* Ensures remote mirrors local (except excluded directories)

---

### Step 2 — Remote → Local

For each directory:

```bash
data/
logs/
outputs/
```

The script runs:

```bash
rsync -avz remote:/dir local:/dir
```

* Pulls runtime-generated files back to local

---

## Important Notes

### No True Bidirectional Sync

This script intentionally avoids full bidirectional sync to prevent:

* File conflicts
* Accidental overwrites
* Complex state tracking

---

### Safe Use of `--delete`

The `--delete` flag is used only in:

```
Local → Remote
```

And excludes critical directories, ensuring:

* No accidental deletion of logs or data on the server

---

### Directory Initialization

Make sure these directories exist locally:

```bash
mkdir -p data logs outputs
```

---

## Optional Improvements

You may enhance the script by adding exclusions:

```bash
--exclude "__pycache__/" \
--exclude "*.pyc" \
--exclude ".git/"
```

---

## Use Cases

* Deploying scripts or applications to a server
* Collecting logs and outputs from remote execution
* Maintaining a clean separation between code and generated data

---

## Summary

This script provides:

* ✅ Predictable synchronization behavior
* ✅ Clear ownership of files
* ✅ Safe handling of deletions
* ✅ No need for timestamps or conflict resolution

It is a **simple and reliable alternative** to full bidirectional sync systems.

---
