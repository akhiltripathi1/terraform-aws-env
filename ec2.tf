data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  user_data = <<-EOF
    #!/bin/bash
    set -eux
    dnf install -y httpd
    systemctl enable httpd
    INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
    AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
    echo "<h1>${local.name}</h1><p>Served by $INSTANCE_ID in $AZ</p>" > /var/www/html/index.html
    systemctl start httpd
  EOF
}

resource "aws_instance" "app" {
  count                       = var.instance_count
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private[count.index % var.az_count].id
  vpc_security_group_ids      = [aws_security_group.app.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  key_name                    = var.key_pair_name
  user_data                   = local.user_data
  associate_public_ip_address = false

  metadata_options {
    http_tokens   = "required" # enforce IMDSv2
    http_endpoint = "enabled"
  }

  root_block_device {
    volume_size           = 8
    volume_type            = "gp3"
    encrypted              = true
    delete_on_termination = true
  }

  tags = {
    Name = "${local.name}-app-${count.index}"
  }
}
