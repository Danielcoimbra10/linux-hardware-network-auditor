# Linux Hardware & Network Inventory Auditor
[![DOI](https://zenodo.org/badge/1472069045.svg)](https://doi.org/10.5281/zenodo.24538610)

Ferramenta desenvolvida em Shell Script (Bash) para coleta automatizada de inventário de hardware, diagnóstico de interfaces de rede e auditoria de sistemas operacionais baseados em Linux, gerando relatórios estruturados nos formatos **TXT** e **JSON**.

## Visão Geral

O levantamento manual de ativos de tecnologia da informação (especificações de placa-mãe, processador, memória, armazenamento e endereçamento de rede) em parques computacionais é lento e propenso a erros de digitação. Este software consulta diretamente interfaces do kernel Linux (`/proc`, `/sys/class/net`, `/sys/devices/virtual/dmi`) e utilitários de sistema para produzir relatórios padronizados prontos para leitura humana ou integração via JSON com sistemas de gestão de ativos.

## Principais Funcionalidades

- **Detecção Dinâmica de Rede:** Identifica automaticamente a interface de rota padrão ativa, extraindo endereço IPv4, Gateway, endereço MAC e velocidade negociada pelo link físico.
- **Inventário Completo de Hardware:** Coleta modelo e contagem de núcleos da CPU, fabricante e modelo da placa-mãe via DMI/SMBIOS, capacidade e tecnologia de memória RAM, controladora gráfica (PCI) e unidade de armazenamento principal.
- **Saída Dupla (TXT e JSON):** Exporta simultaneamente um relatório formatado para auditoria rápida em terminal (`.txt`) e um objeto estruturado (`.json`) para ingestão automatizada.
- **Execução Segura sem Dependências Externas Pesadas:** Utiliza comandos nativos da maioria das distribuições Linux modernas e aplica *fallbacks* caso algum utilitário opcional não esteja instalado.

## Como Utilizar

1. Clone o repositório:
   ```bash
   git clone [https://github.com/Danielcoimbra10/linux-hardware-network-auditor.git](https://github.com/Danielcoimbra10/linux-hardware-network-auditor.git)
   cd linux-hardware-network-auditor
