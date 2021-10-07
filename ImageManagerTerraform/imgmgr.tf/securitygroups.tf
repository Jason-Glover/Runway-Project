###############################################
# LB Security Group
###############################################

resource "aws_security_group" "sg_lb" {
  name               = "${terraform.workspace}-${var.ApplicationName}-LbSg"
  description = "allow http from internet"
  vpc_id      = data.terraform_remote_state.remote_state.outputs.vpc_id
  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

###############################################
# Server Security Group
###############################################

resource "aws_security_group" "ec2" {
  name        = "${terraform.workspace}-${var.ApplicationName}-EC2Sg"
  description = "allow http from internet"
  vpc_id      = data.terraform_remote_state.remote_state.outputs.vpc_id
  ingress {
    from_port = "80"
    to_port   = "80"
    protocol  = "tcp"

    security_groups = [
      "${aws_security_group.sg_lb.id}",
    ]
  }

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}