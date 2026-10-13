# 0011 — A devbox corre o compose de desenvolvimento; os LXC de Kafka e PostgreSQL saem

**Estado:** Aceite · **Data:** 2026-10-13

## Contexto

O desenho inicial tinha três LXC de plataforma — `kafka`, `postgres` e `registry` — para a `devbox`
ter contra o que testar com o OpenShift desligado.

Na prática, o desenvolvimento do dia-a-dia não usa só Kafka e PostgreSQL. Usa um `docker compose` de
trabalho com uma dúzia de serviços — Kafka em três nós, Oracle, Cassandra, SonarQube, WireMock,
SFTP, SMTP, Grafana, Prometheus — que vive no repositório do projecto, é partilhado pela equipa e
traz os seus próprios scripts de arranque, IPs fixos e limites de memória (~13,5 GB no total).

Três factos pesam:

- **Os dados desses serviços são voláteis.** Sobem, servem uma sessão de trabalho e podem ser
  apagados. Não precisam de backup nem de persistência entre reconstruções.
- **O compose é o artefacto canónico da equipa.** Os scripts assumem `localhost` e o comportamento
  do Docker. Partir o ficheiro em contentores do Proxmox seria manter uma cópia divergente.
- **Algumas imagens só existem em `amd64`.** No Mac (ARM) o compose precisa de um *overlay* com
  imagens substitutas. Na `devbox` (x86_64) correm as imagens originais, como nos colegas.

Com o compose a correr na `devbox`, os LXC `kafka` e `postgres` duplicam serviços que já lá estão.
E no perfil `platform` duplicavam também o Kafka (Strimzi) e o PostgreSQL (CloudNativePG) que vivem
dentro do cluster.

## Opções consideradas

| Opção | Notas |
|---|---|
| **Compose dentro da `devbox`, LXC de Kafka e PostgreSQL removidos** | Um só sítio para a infraestrutura de desenvolvimento; scripts inalterados; imagens `amd64` originais |
| **Manter os LXC e correr o compose ao lado** | Dois Kafka e dois PostgreSQL para o mesmo fim; 8 GB a mais em todos os perfis que os ligam |
| **Um LXC por serviço do compose** | Poupança de RAM desprezável face ao Docker; reescrever e manter IPs, arranques e *init* à parte da equipa |
| **VM própria só para o compose** | Isola o compose da IDE, mas os scripts deixam de falar com `localhost` e paga-se um segundo kernel e sistema |

## Decisão

**A `devbox` corre o compose de desenvolvimento.** Sobe para **24 GB**, com balloon **16–24 GB**, e
a imagem `bootc` passa a trazer Docker e o plugin `compose`, além do Podman.

**Os LXC `kafka` e `postgres` saem.** O `registry` fica: guarda imagens para o cluster e para o CI,
e isso não é volátil.

O compose continua no repositório do projecto. **Este repositório é público e não o copia** — só
garante que a `devbox` tem o motor, a memória e a arquitectura para o correr.

## Consequências

**Positivas**

- Os perfis `dev` e `platform` descem de 41 e 49 GB para **39 GB** cada.
- `gaming` + `platform` passa de 81 para **55 GB**: deixa de ser impossível por memória. A GPU
  continua a ser só da `bazzite`, mas o OpenShift já pode estar ligado enquanto se joga. Fica por
  validar no metal antes de virar perfil.
- Menos dois guests para manter, actualizar e salvaguardar.
- O desenvolvimento local corre com as imagens originais do projecto, sem *overlay* ARM.

**Negativas**

- Perde-se o exercício de operar Kafka e PostgreSQL à mão, fora de um operador. O compose
  esconde-o, e o operador do cluster também.
- A `devbox` passa a ser a peça mais pesada a seguir ao OpenShift. O `full-lab` fica em 63 GB à
  letra — continua a precisar dos ajustes de [`capacity.md`](../capacity.md#o-caso-full-lab).
- O compose e a IDE partilham a mesma VM: um serviço que fuja ao seu `mem_limit` afecta o build.
  Mitigação: o próprio compose já impõe limites a todos os serviços.
- Docker e Podman lado a lado numa imagem atómica. Funciona, mas são dois motores para conhecer.
