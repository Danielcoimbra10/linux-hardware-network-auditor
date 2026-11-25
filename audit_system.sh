#!/usr/bin/env bash
# ==============================================================================
# Título: Linux Hardware & Network Inventory Auditor
# Autor: Daniel Coimbra de Oliveira
# Versão: 1.0.0
# Descrição: Ferramenta para auditoria e coleta automatizada de especificações
#            de hardware, sistema operacional, armazenamento e interfaces de
#            rede em estações Linux, exportando relatórios em TXT e JSON.
# ==============================================================================

# ==============================================================================
# 1. DEFINIÇÃO DE DIRETÓRIOS E METADADOS DA EXECUÇÃO
# ==============================================================================
# Captura o nome do usuário atual e o hostname da máquina
CURRENT_USER="$(whoami)"
HOST_NAME="$(hostname)"

# Gera timestamp padronizado (AAAA-MM-DD_HH-MM) para versionamento dos relatórios
TIMESTAMP="$(date '+%Y-%m-%d_%H-%M')"
ISO_DATE="$(date -Iseconds)"

# Define o diretório de saída na pasta do usuário e cria caso não exista
OUTPUT_DIR="$HOME/system_audit_reports"
mkdir -p "$OUTPUT_DIR"

# Define os caminhos completos dos arquivos de saída (TXT e JSON)
TXT_REPORT="${OUTPUT_DIR}/audit_${HOST_NAME}_${TIMESTAMP}.txt"
JSON_REPORT="${OUTPUT_DIR}/audit_${HOST_NAME}_${TIMESTAMP}.json"

# ==============================================================================
# 2. COLETA DE INFORMAÇÕES DO SISTEMA OPERACIONAL
# ==============================================================================
# Obtém a descrição da distribuição Linux via lsb_release (com fallback para /etc/os-release)
if command -v lsb_release &> /dev/null; then
    OS_INFO="$(lsb_release -ds | tr -d '"')"
else
    OS_INFO="$(grep '^PRETTY_NAME=' /etc/os-release | cut -d '=' -f2 | tr -d '"')"
fi

# Obtém a versão do kernel Linux e arquitetura do sistema
KERNEL_VERSION="$(uname -r)"
ARCH="$(uname -m)"

# ==============================================================================
# 3. COLETA DE INFORMAÇÕES DE REDE
# ==============================================================================
# Identifica a interface de rede associada à rota padrão (default gateway)
ACTIVE_IFACE="$(ip -o -4 route show to default 2>/dev/null | awk '{print $5}' | head -n1)"

if [ -n "$ACTIVE_IFACE" ]; then
    # Extrai o endereço IPv4 atribuído à interface ativa
    IP_ADDR="$(ip -o -4 addr show "$ACTIVE_IFACE" 2>/dev/null | awk '{print $4}' | cut -d'/' -f1 | head -n1)"
    # Lê o endereço físico (MAC Address) diretamente do sysfs
    MAC_ADDR="$(cat "/sys/class/net/${ACTIVE_IFACE}/address" 2>/dev/null || echo "N/A")"
    # Extrai o endereço do Gateway padrão
    GATEWAY_IP="$(ip -o -4 route show to default 2>/dev/null | awk '{print $3}' | head -n1)"

    # Verifica a velocidade negociada pelo link físico (em Mbps)
    if [ -r "/sys/class/net/${ACTIVE_IFACE}/speed" ]; then
        LINK_SPEED_RAW="$(cat "/sys/class/net/${ACTIVE_IFACE}/speed" 2>/dev/null)"
        if [[ "$LINK_SPEED_RAW" =~ ^[0-9]+$ ]] && [ "$LINK_SPEED_RAW" -gt 100 ]; then
            LINK_SPEED="10/100/1000 Mbps (${LINK_SPEED_RAW} Mbps ativos)"
        elif [[ "$LINK_SPEED_RAW" =~ ^[0-9]+$ ]] && [ "$LINK_SPEED_RAW" -gt 0 ]; then
            LINK_SPEED="10/100 Mbps (${LINK_SPEED_RAW} Mbps ativos)"
        else
            LINK_SPEED="Desconhecida"
        fi
    else
        LINK_SPEED="Virtual / Sem leitura física"
    fi
else
    ACTIVE_IFACE="Nenhuma interface ativa"
    IP_ADDR="0.0.0.0"
    MAC_ADDR="N/A"
    GATEWAY_IP="N/A"
    LINK_SPEED="Desconectada"
fi

# ==============================================================================
# 4. COLETA DE ESPECIFICAÇÕES DE HARDWARE (CPU, GPU, PLACA-MÃE, RAM E DISCO)
# ==============================================================================
# Extrai e limpa o modelo do processador a partir de /proc/cpuinfo
CPU_MODEL="$(grep -m 1 "model name" /proc/cpuinfo | cut -d ':' -f2 | sed -e 's/^[ \t]*//' -e 's/(R)//g' -e 's/(TM)//g')"
CPU_CORES="$(nproc)"

# Identifica a controladora de vídeo via barramento PCI
GPU_MODEL="$(lspci 2>/dev/null | grep -iE 'vga|3d|display' | cut -d ':' -f3 | sed -e 's/^[ \t]*//' | head -n1)"
GPU_MODEL="${GPU_MODEL:-Não identificada}"

# Lê fabricante e modelo da placa-mãe via tabela DMI/SMBIOS do kernel
BOARD_VENDOR="$(cat /sys/devices/virtual/dmi/id/board_vendor 2>/dev/null || echo "Genérico")"
BOARD_NAME="$(cat /sys/devices/virtual/dmi/id/board_name 2>/dev/null || echo "Não identificado")"
MOTHERBOARD="${BOARD_VENDOR} ${BOARD_NAME}"

# Calcula a memória RAM total em GB a partir de /proc/meminfo
MEM_KB="$(grep "MemTotal" /proc/meminfo | awk '{print $2}')"
MEM_GB="$((MEM_KB / 1024 / 1024))"

# Tenta identificar o tipo de módulo DIMM (ex: DDR3, DDR4) caso executado com privilégios
if command -v lshw &> /dev/null; then
    MEM_TYPE="$(lshw -short -C memory 2>/dev/null | grep -m1 "DIMM" | awk '{print $5}')"
fi
RAM_INFO="${MEM_TYPE:-RAM} ${MEM_GB} GB"

# Obtém o tamanho e modelo do disco principal via lsblk
PRIMARY_DISK="$(lsblk -d -o NAME,SIZE,MODEL -n 2>/dev/null | grep -v '^loop' | head -n1 | tr -s ' ')"
PRIMARY_DISK="${PRIMARY_DISK:-Não identificado}"

# ==============================================================================
# 5. GERAÇÃO DO RELATÓRIO EM FORMATO TEXTO (.TXT)
# ==============================================================================
{
    echo "============================================================"
    echo "       RELATÓRIO DE INVENTÁRIO DE HARDWARE E REDE"
    echo "       Autor: Daniel Coimbra de Oliveira"
    echo "       Data da Coleta: ${ISO_DATE}"
    echo "============================================================"
    echo ""
    echo "[SISTEMA]"
    echo "Sistema Operacional:  ${OS_INFO}"
    echo "Kernel / Arquitetura: ${KERNEL_VERSION} (${ARCH})"
    echo "Hostname:             ${HOST_NAME}"
    echo "Usuário Executor:     ${CURRENT_USER}"
    echo ""
    echo "[REDE]"
    echo "Interface Ativa:      ${ACTIVE_IFACE}"
    echo "Endereço IPv4:        ${IP_ADDR}"
    echo "Gateway Padrão:       ${GATEWAY_IP}"
    echo "Endereço MAC:         ${MAC_ADDR}"
    echo "Velocidade do Link:   ${LINK_SPEED}"
    echo ""
    echo "[HARDWARE]"
    echo "Processador:          ${CPU_MODEL} (${CPU_CORES} núcleos)"
    echo "Placa-Mãe:            ${MOTHERBOARD}"
    echo "Memória RAM:          ${RAM_INFO}"
    echo "Controladora Vídeo:   ${GPU_MODEL}"
    echo "Disco Principal:      ${PRIMARY_DISK}"
    echo "============================================================"
} > "$TXT_REPORT"

# ==============================================================================
# 6. GERAÇÃO DO RELATÓRIO ESTRUTURADO EM FORMATO JSON (.JSON)
# ==============================================================================
cat <<EOF > "$JSON_REPORT"
{
  "metadata": {
    "timestamp": "${ISO_DATE}",
    "collector_user": "${CURRENT_USER}",
    "hostname": "${HOST_NAME}"
  },
  "operating_system": {
    "distribution": "${OS_INFO}",
    "kernel": "${KERNEL_VERSION}",
    "architecture": "${ARCH}"
  },
  "network": {
    "interface": "${ACTIVE_IFACE}",
    "ipv4": "${IP_ADDR}",
    "gateway": "${GATEWAY_IP}",
    "mac_address": "${MAC_ADDR}",
    "link_speed": "${LINK_SPEED}"
  },
  "hardware": {
    "cpu_model": "${CPU_MODEL}",
    "cpu_cores": ${CPU_CORES},
    "motherboard": "${MOTHERBOARD}",
    "memory": "${RAM_INFO}",
    "gpu": "${GPU_MODEL}",
    "primary_storage": "${PRIMARY_DISK}"
  }
}
EOF

# ==============================================================================
# 7. EXIBIÇÃO DO RESULTADO NO TERMINAL
# ==============================================================================
cat "$TXT_REPORT"
echo ""
echo "[OK] Relatório TXT salvo em:  ${TXT_REPORT}"
echo "[OK] Relatório JSON salvo em: ${JSON_REPORT}"

exit 0
