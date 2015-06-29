
resource "aws_security_group" "kubernetes" {
    name = "kubernetes"
    description = "Main kubernetes SG"
    vpc_id = "${aws_vpc.k8vpc.id}"

    ingress = {
        from_port = 80
        to_port = 80
        #cidr_blocks = [ "${aws_subnet.public.cidr_block}" ]
        cidr_blocks = [ "0.0.0.0/0" ]
        protocol = "tcp"
        self = false
    }

    ingress = {
        from_port = 443
        to_port = 443
        cidr_blocks = [ "0.0.0.0/0" ]
        protocol = "tcp"
        self = false
    }

    ingress = {
        from_port = 22
        to_port = 22
        cidr_blocks = [ "0.0.0.0/0" ]
        protocol = "tcp"
        self = false
    }

    ingress = {
        from_port = 0
        to_port = 0
        protocol = "-1"
        self = true
    }

    egress = {
        from_port = 0
        to_port = 0
        protocol = "-1"
        #cidr_blocks = [ "${aws_subnet.public.cidr_block}" ]
        cidr_blocks = [ "0.0.0.0/0" ]
    }

}


resource "aws_instance" "kubernetes-master" {

    connection {
        key_file = "${var.key_path}"
    }

    ami = "${lookup(var.coreos_amis, var.region)}"

    instance_type = "m3.medium"

    key_name = "${var.key_name}"

    security_groups = [
        "${aws_security_group.kubernetes.id}"
    ]

    subnet_id = "${aws_subnet.public.id}"

    associate_public_ip_address = true
    private_ip = "10.0.0.10"

    tags = {
        Name = "Kubernetes Master"
        subnet = "public"
        role = "master"
        environment = "dev"
    }

    user_data = "${file(\"./cloud-configs/master.yml\")}"
}

resource "aws_instance" "kubernetes-node" {
    depends_on = [ "aws_instance.kubernetes-master" ]

    connection {
        key_file = "${var.key_path}"
    }

    ami = "${lookup(var.coreos_amis, var.region)}"

    count = 3

    instance_type = "t2.small"

    key_name = "${var.key_name}"

    security_groups = [
        "${aws_security_group.kubernetes.id}"
    ]

    subnet_id = "${aws_subnet.public.id}"

    associate_public_ip_address = true

    tags = {
        Name = "Kubernetes Node ${count.index + 1}"
        subnet = "public"
        role = "node"
        environment = "dev"
    }

    user_data = "${file(\"./cloud-configs/node.yml\")}"
}

output "master-ip" {
    value = "${aws_instance.kubernetes-master.public_ip}"
}