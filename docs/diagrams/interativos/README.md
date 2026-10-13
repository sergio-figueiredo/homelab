# Diagramas interactivos

Três diagramas gerados com [archify](https://github.com/tt-a1i/archify), complementares aos SVG de
`docs/diagrams/`. Os SVG são para ler no README; estes são para explorar: zoom, foco num nó, tema
claro e escuro, e cada nó liga à linha do repositório que o justifica.

| Diagrama | O que mostra | Pré-visualização |
|---|---|---|
| [topologia.html](topologia.html) | Do hardware do `forge` aos guests: CCD, GPU, disco, rede | [topologia.png](topologia.png) |
| [infra.html](infra.html) | Guests e serviços no Proxmox, backup, monitorização, passthrough | [infra.png](infra.png) |
| [rede.html](rede.html) | VLANs, endereços e só os fluxos que a firewall deixa passar | [rede.png](rede.png) |

O GitHub não renderiza HTML: descarrega o ficheiro e abre-o no browser.

## Regenerar

Cada `.json` é a especificação do diagrama, com as referências ao código fixadas num commit. Depois de
mudar a arquitectura, actualiza o `.json` (incluindo `meta.repository.revision`) e corre:

```bash
node <archify>/bin/archify.mjs finalize architecture docs/diagrams/interativos/rede.json \
  docs/diagrams/interativos/rede.html --repo-root . --quality showcase
```

As referências de linha são verificadas contra o commit fixado — um diagrama desactualizado falha
em vez de mentir.
