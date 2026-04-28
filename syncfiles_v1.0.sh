#!/bin/bash

# NÃO usar set -e aqui

# ===== CONFIG =====
USER="ubuntu"
HOST="IP"
KEY="$HOME/.ssh/portal-cloud-keys"

LOCAL_BASE="/home/essiassouza/GCP-scripts"
REMOTE_BASE="/home/ubuntu/GCP-scripts"

IGNORE_FILE="syncignore"
STATE_FILE="sync_last_sync"

SSH_OPTS="-i $KEY -o StrictHostKeyChecking=no"

echo "============================="
echo "Sync bidirecional inteligente"
echo "============================="

# ===== PREP =====
mkdir -p "$LOCAL_BASE"
ssh $SSH_OPTS $USER@$HOST "mkdir -p '$REMOTE_BASE'"

# ===== STATE =====
if [ -f "$STATE_FILE" ] && [ -s "$STATE_FILE" ]; then
    LAST_SYNC=$(cat "$STATE_FILE")
else
    LAST_SYNC=0
fi

echo "Ultima sincronizacao: $LAST_SYNC"

# ===== DELEÇÕES =====
echo "[1/3] Tratando delecoes..."

cd "$LOCAL_BASE" || exit 1

# -------- LOCAL -> REMOTO (checando deleção remota) --------
while IFS= read -r FILE; do
    FILE_CLEAN="${FILE#./}"

    LOCAL_FILE="$LOCAL_BASE/$FILE_CLEAN"
    REMOTE_FILE="$REMOTE_BASE/$FILE_CLEAN"

    ssh $SSH_OPTS $USER@$HOST "[ -f '$REMOTE_FILE' ]" >/dev/null 2>&1
    EXISTS_REMOTE=$?

    if [ $EXISTS_REMOTE -ne 0 ]; then
        LOCAL_MTIME=$(stat -c %Y "$LOCAL_FILE")

        if [ "$LOCAL_MTIME" -le "$LAST_SYNC" ]; then
            echo "Removendo local (apagado remoto): $FILE_CLEAN"
            rm -f "$LOCAL_FILE"
        fi
    fi
done < <(find . -type f)

# -------- REMOTO -> LOCAL (checando deleção local) --------
REMOTE_LIST=$(ssh $SSH_OPTS $USER@$HOST "cd '$REMOTE_BASE' && find . -type f 2>/dev/null")

while IFS= read -r FILE; do
    FILE_CLEAN="${FILE#./}"

    LOCAL_FILE="$LOCAL_BASE/$FILE_CLEAN"
    REMOTE_FILE="$REMOTE_BASE/$FILE_CLEAN"

    if [ ! -f "$LOCAL_FILE" ]; then
        REMOTE_MTIME=$(ssh $SSH_OPTS $USER@$HOST "stat -c %Y '$REMOTE_FILE'" 2>/dev/null)

        if [ -n "$REMOTE_MTIME" ] && [ "$REMOTE_MTIME" -le "$LAST_SYNC" ]; then
            echo "Removendo remoto (apagado local): $FILE_CLEAN"
            ssh $SSH_OPTS $USER@$HOST "rm -f '$REMOTE_FILE'"
        fi
    fi
done <<< "$REMOTE_LIST"

# ===== RSYNC OPTIONS =====
RSYNC_BASE="-avzu"

if [ -f "$IGNORE_FILE" ]; then
    RSYNC_BASE="$RSYNC_BASE --exclude-from=$IGNORE_FILE"
fi

# ===== ETAPA 2 =====
echo ""
echo "[2/3] Remoto -> Local..."

rsync $RSYNC_BASE \
-e "ssh $SSH_OPTS" \
"$USER@$HOST:$REMOTE_BASE/" \
"$LOCAL_BASE/"

# ===== ETAPA 3 =====
echo ""
echo "[3/3] Local -> Remoto..."

rsync $RSYNC_BASE \
-e "ssh $SSH_OPTS" \
"$LOCAL_BASE/" \
"$USER@$HOST:$REMOTE_BASE/"

# ===== FINALIZA =====
date +%s > "$STATE_FILE"

echo ""
echo "============================="
echo "Sync concluido"
echo "============================="
