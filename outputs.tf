output "public ip of cm-test" {
  value = "${aws_instance.cm_test.public_ip}"
}
