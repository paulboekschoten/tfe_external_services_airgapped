output "public_ip" {
  value = aws_eip.eip_tfe.public_ip
}