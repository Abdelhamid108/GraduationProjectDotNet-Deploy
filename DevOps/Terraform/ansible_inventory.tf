# Generate Ansible Inventory file
resource "local_file" "ansible_inventory" {
  filename = "../Ansible/inventory/hosts.ini"
  content = templatefile("${path.module}/ansible_inventory.tpl", {
    server_public_ip = aws_eip.ema2a_public_ip.public_ip
  })
}

