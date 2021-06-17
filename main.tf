terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

variable "public_key" {
  type = string
}
variable "jenkinsInstanceName" {
  type    = string
  default = "ohcfsjenkinspl"
}
variable "instance_type" {
  type    = string
  default = "t3.small"
}
variable "vpc" {
  type    = string
  default = "vpc-07e029f6b02a92b5e"
}
variable "subnets" {
  type    = list(string)
  default = ["subnet-0f89de4f490bc2f1a","subnet-0f9f26a45feb0d549"]
}
# variable "vpc" {
#   type    = string
#   default = "vpc-018481742f0dfd2d0"
# }
# variable "subnets" {
#   type    = list(string)
#   default = ["subnet-04a37dd89db10c05e","subnet-0708558cad4d89770"]
# }

variable "ingress_rules" {
  type    = list(number)
  default = [22, 80, 443]
}
variable "egress_rules" {
  type    = list(number)
  default = [0]
}

resource "aws_key_pair" "jenkins_key" {
  key_name   = "jenkins-key"
  public_key = var.public_key
}


data "aws_ami_ids" "jenkins_ami" {
  sort_ascending = false

  owners = ["aws-marketplace"]

  filter {
    name   = "name"
    values = ["bitnami-jenkins*"]
  }
}

resource "aws_security_group" "jenkins_elb_security_group" {
  name        = "Jenkins ELB Security Group"
  description = "Allow traffic to access Jenkins Load Balancer"
  vpc_id = var.vpc

  dynamic "ingress" {
    iterator = port
    for_each = var.ingress_rules
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "jenkins_security_group" {
  name        = "Jenkins Security Group"
  description = "Allow traffic to access Jenkins instrance"
  vpc_id = var.vpc

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = -1
    security_groups = [aws_security_group.jenkins_elb_security_group.id]
    self            = true
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_elb" "jenkins_elb" {
  name            = "jenkins-elb"
  subnets         = var.subnets
  security_groups = [
    aws_security_group.jenkins_elb_security_group.id
  ]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  listener {
    instance_port     = 22
    instance_protocol = "tcp"
    lb_port           = 22
    lb_protocol       = "tcp"
  }

  # listener {
  #   instance_port      = 8000
  #   instance_protocol  = "http"
  #   lb_port            = 443
  #   lb_protocol        = "https"
  #   ssl_certificate_id = "arn:aws:iam::123456789012:server-certificate/certName"
  # }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:22"
    interval            = 30
  }

  tags = {
    Name = "jenkins-elb"
  }
}

resource "aws_launch_template" "jenkins_template" {
  name_prefix   = "jenkins"
  image_id      = data.aws_ami_ids.jenkins_ami.ids[0]
  instance_type = var.instance_type
  key_name      = aws_key_pair.jenkins_key.key_name

  vpc_security_group_ids  = [
    aws_security_group.jenkins_security_group.id
  ]
}

resource "aws_autoscaling_group" "jenkins_asg" {
  name                 = "jenkins-asg"
  max_size             = 1
  min_size             = 1
  vpc_zone_identifier  = var.subnets

  launch_template {
    id      = aws_launch_template.jenkins_template.id
    version = "$Latest"
  }

  tags = [
      {
        "key"                 = "Name"
        "value"               = var.jenkinsInstanceName
        "propagate_at_launch" = true
      },
      {
        "key"                 = "Customer"
        "value"               = "metricstream"
        "propagate_at_launch" = true
      },
      {
        "key"                 = "Purpose"
        "value"               = "jenkins"
        "propagate_at_launch" = true
      },
      {
        "key"                 = "Contact"
        "value"               = "cloudops"
        "propagate_at_launch" = true
      },
      {
        "key"                 = "Department"
        "value"               = "cloudops"
        "propagate_at_launch" = true
      },
      {
        "key"                 = "Environment"
        "value"               = "production"
        "propagate_at_launch" = true
      }
    ]
}

resource "aws_autoscaling_attachment" "asg_attachment_jenkins" {
  autoscaling_group_name = aws_autoscaling_group.jenkins_asg.id
  elb                    = aws_elb.jenkins_elb.id
}

output "jenkins_dns_name" {
  description = "The dns name for the Jenkins deployment."
  value       = aws_elb.jenkins_elb.dns_name
}
