output "outHostname" {
  value = aws_db_instance.ourDBInst.address
}

output "outPort" {
  value = aws_db_instance.ourDBInst.port
}

output "outUsername" {
  value = aws_db_instance.ourDBInst.username
}
