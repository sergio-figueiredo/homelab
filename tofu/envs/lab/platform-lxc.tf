# ─── Cartão de leitura ────────────────────────────────────────────────────────
#  O QUE FAZ      Declara o contentor de plataforma que sobra: o registry OCI.
#  PORQUE EXISTE  Guarda imagens para o cluster e para o CI, ligado ou não o OpenShift.
#                 Ao contrário dos serviços de desenvolvimento, isto não é volátil.
#  SE TIRARES     As imagens construídas fora do cluster não têm onde ficar.
#  ONDE APRENDER  docs/percurso.md — etapa 0 para VM contra contentor, etapa 8 para os serviços
# ──────────────────────────────────────────────────────────────────────────────
#
#  Kafka e PostgreSQL já tiveram aqui um LXC cada. Saíram: o compose de
#  desenvolvimento corre na devbox e traz esses e outros serviços, com dados
#  voláteis. Ver docs/adr/0011-devbox-como-maquina-do-compose.md.

module "registry" {
  source = "../../modules/proxmox-lxc"

  name        = "registry"
  vm_id       = 202
  node_name   = var.node_name
  description = "Registry OCI local · imagens do dia-a-dia"
  tags        = concat(local.common_tags, ["plataforma"])

  cores        = 2
  memory_mb    = 2048
  disk_size_gb = 60
  datastore_id = var.datastore_id

  template_file_id = var.debian_template
  vlan_id          = local.vlan.platform
  ipv4_address     = local.net.registry.addr
  ipv4_gateway     = local.net.registry.gw
  ssh_public_keys  = var.ssh_public_keys

  # o registry corre em Podman dentro do contentor
  features = {
    nesting = true
    keyctl  = true
  }
}
