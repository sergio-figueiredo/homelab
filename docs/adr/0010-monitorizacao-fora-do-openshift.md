# 0010 — Monitorização da máquina num LXC sempre ligado, fora do OpenShift

**Estado:** Aceite · **Data:** 2026-10-13

## Contexto

O plano de observabilidade estava todo dentro do OpenShift: o Prometheus do user-workload
monitoring e o Grafana Operator. Chega para a aplicação de demonstração. Não chega para a máquina.

O `ocp-sno` é **sob procura** ([0008](0008-perfis-de-memoria.md)). Na maior parte do tempo está
desligado — em particular no perfil `gaming`, que é exactamente quando interessa ver temperaturas e
consumo. Um monitor que só existe quando o cluster está ligado não vê o que acontece com o cluster
desligado.

O que se quer ver, sempre:

- **Host Proxmox:** temperatura e uso por CCD, consumo de cada VM.
- **GPU:** temperatura e carga durante os jogos. Está em passthrough na `bazzite`, por isso o host
  não a consegue ler.
- **OpenShift:** as métricas do cluster quando está ligado, no mesmo sítio que as outras.

E mostrá-lo no tablet da parede e no iPhone ([0009](0009-casa-inteligente-home-assistant.md)).

## Opções consideradas

| Opção | Notas |
|---|---|
| **LXC `monitoring` com Prometheus e Grafana, no `idle`** | ~1 GB de RAM; sempre ligado; o OpenShift federa para ele quando sobe |
| **Só o Prometheus do OpenShift** | Zero custo extra; cego sempre que o cluster está desligado |
| **Métricas no próprio Home Assistant** | O HA guarda histórico, mas não é uma TSDB; consultas e retenção ficam fracas |
| **Serviço de monitorização em cloud** | Tira a carga da máquina; manda métricas da casa para fora, contra o princípio de [0009](0009-casa-inteligente-home-assistant.md) |

## Decisão

**Um LXC `monitoring`**, com Prometheus e Grafana, ~1 GB de RAM, na **VLAN 20 (`PLATFORM`)**,
**sempre ligado** — entra no perfil `idle`.

Fontes:

| Fonte | Exporter | Onde corre |
|---|---|---|
| Host Proxmox | `node_exporter` com `lm-sensors` | no host |
| Consumo por VM | `pve-exporter` | no próprio LXC, contra a API do Proxmox, com token só de leitura |
| GPU | `node_exporter` com o coletor `amdgpu` | dentro da `bazzite`, metido no Containerfile `bootc` |
| OpenShift | federação ou *remote write* do Prometheus do cluster | no cluster, quando ligado |

O Grafana é mostrado no HA por um cartão *iframe* (`allow_embedding` e um utilizador *viewer*
anónimo ou *auth proxy*). Alternativa mais leve, se o iframe pesar no tablet: gráficos nativos com o
ApexCharts card a ler do Prometheus.

**Porquê a VLAN 20 e não a 10.** Na `MGMT`, o Prometheus raspava tudo sem regras novas, mas o tablet
(VLAN 30) teria de chegar ao Grafana — e a `MGMT` nunca é alcançável a partir da `IOT`. Na `PLATFORM`
custam duas regras estreitas de saída, só a partir deste LXC: para os exporters do host e para o
`node_exporter` da `bazzite`. É preferível abrir caminho de saída a partir de um serviço do que abrir
a gestão a um segmento não-confiável.

## Consequências

**Positivas**

- A máquina vê-se a qualquer hora, incluindo durante os jogos e com o cluster desligado.
- O Prometheus do OpenShift continua a ser o do cluster; este não o substitui, recebe dele.
- Um painel no tablet e no iPhone, sem expor nada à Internet.

**Negativas**

- O `idle` sobe de 12 para ~13 GB, e todos os perfis com ele. O `full-lab` passa a 65 GB à letra —
  acima do tecto. Com os ajustes de [`capacity.md`](../capacity.md#o-caso-full-lab) fica em ~59 GB;
  a margem desce de 6 para 5 GB.
- Mais um guest sempre ligado para manter actualizado e no backup.
- Dois Prometheus no lab. Mitigado por papéis claros: o do cluster é do cluster, este é da máquina.
- Regras novas na matriz de fluxo: `PLATFORM → MGMT` e `PLATFORM → GAMING` deixam de ser um ❌ limpo.
- Um exporter dentro da `bazzite`: a imagem de jogos passa a ter um serviço que não é de jogos.
