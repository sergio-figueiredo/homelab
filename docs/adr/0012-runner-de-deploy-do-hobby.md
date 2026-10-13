# 0012 — Runner self-hosted de deploy num LXC próprio, efémero e sob procura

**Estado:** Aceite · **Data:** 2026-10-13

## Contexto

Um projecto pessoal, fora deste repositório, faz deploy por GitHub Actions. Os minutos dos runners
alojados pelo GitHub custam, e o deploy precisa de chegar a sítios que só se alcançam a partir de
casa. Um runner *self-hosted* no forge resolve as duas coisas.

Um runner self-hosted executa código vindo de um repositório, com os segredos de deploy desse
repositório. É, por definição, a peça menos confiável que se pode pôr dentro do lab.

Este ADR não trata o runner para `tofu apply` deste repositório — esse continua em aberto no
[roadmap](../roadmap.md#em-aberto) e precisa de uma decisão própria.

## Opções consideradas

| Opção | Notas |
|---|---|
| **LXC `runner` dedicado, efémero, sob procura** | ~2 GB; isolado do resto; cada job começa limpo; liga-se quando há deploy |
| **Runner dentro da `devbox`** | Zero guests novos; o código de CI partilha a máquina com o código e as credenciais do trabalho |
| **Runner como pod no OpenShift (Actions Runner Controller)** | Elegante e efémero por natureza; só existe com o cluster ligado, 24 GB para correr um deploy |
| **Ficar nos runners do GitHub** | Zero manutenção; paga minutos e não chega à rede de casa |

## Decisão

**Um LXC `runner`**, ~2 GB, na **VLAN 20 (`PLATFORM`)**, em `10.10.20.25`, **sob procura**.

- **Efémero.** O runner regista-se com `--ephemeral`: aceita um job, termina, e o serviço volta a
  registá-lo limpo. Nada de um job sobrevive para o seguinte.
- **Só repositórios privados.** Num repositório público, um PR vindo de um fork pode correr código
  arbitrário num runner self-hosted. O runner fica registado apenas no repositório privado do
  projecto.
- **Rede.** Na `PLATFORM` sai para a Internet e não alcança `MGMT`, `IOT`, `GAMING` nem `DEV`. Partilha
  o segmento com o cluster e o registry, o que serve para publicar imagens.
- **Sob procura.** Se o runner estiver desligado, os jobs ficam em fila à espera dele. Liga-se antes de
  um deploy, ou passa para o `idle` se os deploys tiverem de sair sozinhos.
- Se o deploy construir imagens, o LXC usa `nesting`, como o `registry`.

## Consequências

**Positivas**

- Deploys sem minutos pagos e com acesso ao que só existe em casa.
- O código de CI nunca toca na `devbox` nem nas credenciais do trabalho.
- Jobs efémeros: um job comprometido não deixa nada ao seguinte.

**Negativas**

- Mais um guest para actualizar. O binário do runner tem de acompanhar as versões que o GitHub aceita.
- Partilhar a `PLATFORM` com o cluster e o registry é um compromisso: um runner comprometido chega a
  eles. Se isso deixar de ser aceitável, o passo seguinte é uma VLAN própria só com saída para a
  Internet.
- Desligado, os deploys esperam. É uma escolha de consumo, não um defeito, mas convém lembrar.
