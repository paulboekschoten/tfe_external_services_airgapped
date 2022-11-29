output "public_ip" {
  value = aws_eip.eip_tfe.public_ip
}

output "ssh_login" {
  description = "SSH login command."
  value       = "ssh -i tfesshkey.pem ubuntu@${local.fqdn}"
}