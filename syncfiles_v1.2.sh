#!/bin/bash

# ===== CONFIG =====
USER="ubuntu"
HOST="IP"
KEY="$HOME/.ssh/portal-cloud-keys"

LOCAL_BASE="/home/essiassouza/GCP-scripts"
REMOTE_BASE="/home/ubuntu/GCP-scripts"

SSH_OPTS="-i $KEY -o StrictHostKeyChecking=no"

# Diretórios que vêm do remoto
REMOTE_DIRS=("data" "logs" "outputs")

echo "============================="
echo "Sync direcional inteligente"
echo "============================="

# Garante diretório remoto
ssh $SSH_OPTS $USER@$HOST "mkdir -p '$REMOTE_BASE'"

# =============================
# ETAPA 1: LOCAL -> REMOTO
# =============================
echo ""
echo "[1/2] Local -> Remoto (projeto)"

rsync -avz --delete \
--exclude "data/" \
--exclude "logs/" \
--exclude "outputs/" \
-e "ssh $SSH_OPTS" \
"$LOCAL_BASE/" \
"$USER@$HOST:$REMOTE_BASE/"

if [ $? -ne 0 ]; then
    echo "Erro no envio para remoto"
    exit 1
fi

# =============================
# ETAPA 2: REMOTO -> LOCAL (dirs específicos)
# =============================
echo ""
echo "[2/2] Remoto -> Local (data/logs/outputs)"

for DIR in "${REMOTE_DIRS[@]}"; do
    echo "Sincronizando $DIR..."

    rsync -avz \
    -e "ssh $SSH_OPTS" \
    "$USER@$HOST:$REMOTE_BASE/$DIR/" \
    "$LOCAL_BASE/$DIR/"

    if [ $? -ne 0 ]; then
        echo "Erro ao sincronizar $DIR"
        exit 1
    fi
done

echo ""
echo "============================="
echo "Sync concluido"
echo "============================="
