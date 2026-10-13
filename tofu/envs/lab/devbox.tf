# ─── Cartão de leitura ────────────────────────────────────────────────────────
#  O QUE FAZ      Declara a VM de desenvolvimento — onde o código compila.
#  PORQUE EXISTE  O teu Mac é ARM e o cluster é x86_64. Uma imagem nativa do GraalVM
#                 compilada no Mac não arranca no OpenShift. Esta VM é x86_64.
#  SE TIRARES     Perdes o sítio onde compilar para a arquitectura certa. Podes viver sem
#                 ela até à fase 3 do roadmap.
#  ONDE APRENDER  docs/percurso.md — etapa 9, e a nota honesta sobre o Fedora Silverblue
# ──────────────────────────────────────────────────────────────────────────────
#
#  `memory_floating_mb = 16384` liga o ballooning entre 16 e 24 GB: a devbox
#  corre a IDE remota e o compose de desenvolvimento (~13,5 GB de limites),
#  e um build native-image pede o resto. É o único guest do lab onde o
#  ballooning faz sentido. Ver docs/adr/0011-devbox-como-maquina-do-compose.md.
#
#  `clone_vm_id` faz nascer esta VM de um template Packer em vez de uma ISO.

module "devbox" {
  source = "../../modules/proxmox-vm"

  name        = "devbox"
  vm_id       = 130
  node_name   = var.node_name
  description = "Bancada de desenvolvimento · alvo do JetBrains Gateway"
  tags        = concat(local.common_tags, ["dev"])

  cores        = 8
  cpu_affinity = var.cpu_ccd1_cpus
  memory_mb    = 24576

  # balloon 16-24: o compose fica sempre em cima; o native-image leva o
  # resto quando compila. Ver docs/capacity.md
  memory_floating_mb = 16384

  disk_size_gb = 150
  datastore_id = var.datastore_id

  vlan_id      = local.vlan.dev
  mac_address  = local.mac.devbox
  ipv4_address = local.net.devbox.addr
  ipv4_gateway = local.net.devbox.gw

  on_boot = false
  started = false

  clone_vm_id     = var.fedora_template_vm_id
  ssh_public_keys = var.ssh_public_keys
  username        = var.username
}
