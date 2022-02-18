output "outHostname" {
  value = aws_db_instance.ourDBInst.address
  sensitive = true
}

output "outPort" {
  value = aws_db_instance.ourDBInst.port
  sensitive = true
}

output "outUsername" {
  value = aws_db_instance.ourDBInst.username
  sensitive = true
}
