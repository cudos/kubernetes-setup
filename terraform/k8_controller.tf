# k8_controller.tf


resource "aws_instance" "controller" {
    count = 3
    ami = "${lookup(var.amis, var.region)}"
    instance_type = "${var.controller_instance_type}"

#    iam_instance_profile = "${aws_iam_instance_profile.kubernetes.id}"

    subnet_id = "${aws_subnet.kubernetes.id}"
    private_ip = "${cidrhost(var.vpc_cidr, 20 + count.index)}"
    associate_public_ip_address = true # Instances have public, dynamic IP
    source_dest_check = false # TODO Required??

    availability_zone = "${var.zone}"
    vpc_security_group_ids = ["${aws_security_group.kubernetes.id}"]
    key_name = "${var.default_keypair_name}"

    tags {
      Owner = "${var.owner}"
      Name = "controller-${count.index}"
#       ansibleFilter = "${var.ansibleFilter}"
#       ansibleNodeType = "controller"
#       ansibleNodeName = "controller${count.index}"
    }
}
