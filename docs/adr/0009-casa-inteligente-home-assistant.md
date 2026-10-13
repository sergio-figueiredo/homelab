# 0009 — Home Assistant como cérebro da casa

**Estado:** Aceite · **Data:** 2026-10-13

## Contexto

O `haos` já está no perfil `idle` e já tem lugar na VLAN 30. Faltava decidir o que é que manda na
casa: que plataforma guarda as automações, quem fala Matter e Thread, e por onde é que se interage
com ela — um painel na parede, o telemóvel, um assistente de voz.

Restrições que vêm de antes deste ADR:

- **Sem dependência de clouds de terceiros.** A casa não depende de um serviço externo que pode mudar
  os termos amanhã.
- **Local primeiro.** Câmaras e campainha têm de dar stream na rede de casa (RTSP/ONVIF), sem passar
  por um serviço externo.
- **Já existe um hub Matter/Thread na LAN de casa**, fora deste repositório.

## Opções consideradas

| Opção | Notas |
|---|---|
| **Home Assistant como cérebro, hub existente para Matter/Thread** | Automações em YAML versionável; o hub já existe e é border router Thread; os ecossistemas de voz continuam a funcionar por uma ponte do HA |
| **Só o ecossistema do fabricante do hub** | Zero manutenção; automações limitadas, sem câmaras RTSP genéricas, nada versionável |
| **Assistentes de voz com cloud obrigatória** | Excluído à partida pela restrição acima |
| **Home Assistant sozinho, com dongle Thread próprio** | Possível; duplica o papel que o hub já faz. Fica como passo seguinte, não como base |

## Decisão

**O Home Assistant é o cérebro.** Automações, integrações, dashboards e histórico vivem no `haos`,
com a configuração versionada.

**O hub existente fica com Matter/Thread.** O HA expõe dispositivos e câmaras a esse ecossistema por
uma ponte de integração — o ecossistema passa a ser mais uma janela sobre a casa, não a fonte da
verdade.

**Interfaces:**

- **Painel de parede** em modo kiosk, com um utilizador restrito no HA. Fica na VLAN 30. Abas de
  Câmaras, Máquina e Casa; um popup em ecrã inteiro com a câmara da porta quando tocam à campainha
  (`browser_mod`).
- **Telemóvel** pela app do Home Assistant: o mesmo dashboard, numa vista própria para ecrã pequeno,
  e notificação *push* com a imagem da campainha em vez do popup.
- **Câmaras e campainha** só com stream local (RTSP/ONVIF), mostradas pelo Advanced Camera Card com o
  `go2rtc` embutido no HA. *Substreams* na grelha, para o painel não aquecer.

## Consequências

**Positivas**

- A casa funciona sem Internet: automações, câmaras e dashboards são locais.
- Uma só fonte da verdade, com configuração em Git, coerente com o resto do lab.
- Thread e Matter sem comprar mais um hub.
- Quem não quer saber do HA continua a usar o ecossistema que já conhece.

**Negativas**

- O `haos` passa a ser crítico para a casa, não só para o lab. Reforça que tem de ficar no `idle` e
  que o backup dele não é opcional.
- O hub vive na LAN de casa e o HA na VLAN 30. A ponte e a descoberta das apps precisam de um
  repetidor mDNS e de regras específicas entre os dois segmentos — ver
  [`network.md`](../network.md#casa-inteligente).
- Câmaras e campainha têm de ser escolhidas pelo stream local; as que só funcionam pela cloud do
  fabricante ficam de fora.
- Dois controladores Matter (o hub e o HA) obrigam a escolher, dispositivo a dispositivo, quem o
  comissiona primeiro.
