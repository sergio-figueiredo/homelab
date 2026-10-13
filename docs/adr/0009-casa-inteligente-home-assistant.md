# 0009 — Home Assistant como cérebro da casa, ecossistema Apple como janela

**Estado:** Aceite · **Data:** 2026-10-13

## Contexto

O `haos` já está no perfil `idle` e já tem lugar na VLAN 30. Faltava decidir o que é que manda na
casa: que plataforma guarda as automações, que hub fala Matter e Thread, e por onde é que as pessoas
da casa interagem com ela — um ecrã na parede, o iPhone, a Siri.

Restrições que vêm de antes deste ADR:

- **Sem Amazon nem Google.** Nada de Alexa, Nest ou Ring. A casa não depende de uma cloud que pode
  mudar os termos amanhã.
- **Local primeiro.** Câmaras e campainha têm de dar stream na rede de casa (RTSP/ONVIF), sem passar
  por um serviço externo.
- **Já há HomePod em casa**, e o iPhone é o telefone de toda a gente.

## Opções consideradas

| Opção | Notas |
|---|---|
| **Home Assistant como cérebro, HomePod como hub Matter/Thread** | Automações em YAML versionável; HomePod já existe e é border router Thread; o app Casa e a Siri continuam a funcionar via HomeKit Bridge |
| **Só Apple Home** | Zero manutenção; automações limitadas, sem câmaras RTSP genéricas, nada versionável |
| **Apple Home Collection** | Não está disponível na UE. Fora, por agora |
| **Alexa ou Google Home** | Excluído à partida pela restrição acima |
| **Home Assistant sozinho, com dongle Thread próprio** | Possível; duplica o papel que o HomePod já faz. Fica como passo seguinte, não como base |

## Decisão

**O Home Assistant é o cérebro.** Automações, integrações, dashboards e histórico vivem no `haos`,
com a configuração versionada.

**O HomePod é o hub Matter/Thread** e o controlador da porta. O HA expõe dispositivos e câmaras ao
app Casa e à Siri pela integração **HomeKit Bridge** — o ecossistema Apple passa a ser mais uma
janela sobre a casa, não a fonte da verdade.

**Interfaces:**

- **Tablet na parede**, Wi-Fi, em modo kiosk (Fully Kiosk Browser) com um utilizador restrito no HA.
  Fica na VLAN 30. Abas de Câmaras, Máquina e Casa; um popup em ecrã inteiro com a câmara da porta
  quando tocam à campainha (`browser_mod`).
- **iPhone** pela app oficial do Home Assistant: o mesmo dashboard, numa vista própria para ecrã
  pequeno, e notificação *push* com a imagem da campainha em vez do popup.
- **Câmaras e campainha** só com stream local (RTSP/ONVIF), mostradas pelo Advanced Camera Card com o
  `go2rtc` embutido no HA. *Substreams* na grelha, para o tablet não aquecer.

## Consequências

**Positivas**

- A casa funciona sem Internet: automações, câmaras e dashboards são locais.
- Uma só fonte da verdade, com configuração em Git, coerente com o resto do lab.
- O HomePod já existe: Thread e Matter sem comprar mais um hub.
- Quem não quer saber do HA continua a usar o app Casa e a Siri.

**Negativas**

- O `haos` passa a ser crítico para a família, não só para o lab. Reforça que tem de ficar no `idle`
  e que o backup dele não é opcional.
- O HomePod vive na LAN de casa e o HA na VLAN 30. A HomeKit Bridge e a descoberta das apps precisam
  de um repetidor mDNS e de regras específicas entre os dois segmentos — ver
  [`network.md`](../network.md#casa-inteligente).
- Ring, Nest e afins ficam excluídos. Câmaras e campainha têm de ser escolhidas pelo stream local
  (Reolink, Amcrest e semelhantes).
- Dois controladores Matter (HomePod e HA) obrigam a escolher, dispositivo a dispositivo, quem o
  comissiona primeiro.
