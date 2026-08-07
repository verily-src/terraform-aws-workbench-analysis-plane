output "global" {
  value = file("${path.module}/Environment.avsc")
}

output "regional" {
  value = file("${path.module}/LandingZone.avsc")
}
