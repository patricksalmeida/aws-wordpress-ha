locals {
  wp_url = "https://${var.host}"
}

resource "aws_security_group" "wp_ec2_sg" {
  name   = "${var.name}-${var.environment}-node-sg"
  vpc_id = var.vpc_id

  ingress {
    description     = "Allow http request from Load Balancer"
    protocol        = "tcp"
    from_port       = 80
    to_port         = 80
    security_groups = [aws_security_group.wp_alb_sg.id]
  }

  ingress {
    description = "Allow internal ssh connections"
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.name}-${var.environment}-node-sg"
    Environment = "${var.environment}"
  }
}

resource "random_password" "wp_salt" {
  length           = 64
  special          = true
  override_special = "@#&()+-_"
}

resource "random_password" "wp_admin_password" {
  length           = 32
  special          = true
  override_special = "@#&()+-_"
}

resource "aws_secretsmanager_secret" "wp_admin_password_sm" {
  name = "${var.name}-${var.environment}-wp-admin-pass-sm"

  tags = {
    Name        = "${var.name}-${var.environment}-wp-admin-pass-sm"
    Environment = "${var.environment}"
  }
}

resource "aws_secretsmanager_secret_version" "wp_admin_password_sm_version" {
  secret_id     = aws_secretsmanager_secret.wp_admin_password_sm.id
  secret_string = random_password.wp_admin_password.result
}

data "template_file" "startup_script" {
  template = filebase64("${path.module}/files/user_data.tpl")

  vars = {
    WP_SITEURL         = local.wp_url
    WP_HOME            = local.wp_url
    WP_ALLOW_MULTISITE = var.enable_multisite
    WPLANG             = "pt_BR"

    DB_NAME     = aws_db_instance.wp_db_primary.db_name
    DB_USER     = var.db.username
    DB_PASSWORD = random_password.wp_db_password.result
    DB_HOST     = aws_db_instance.wp_db_primary.address
    DB_CHARSET  = "utf-8"
    DB_COLLATE  = ""

    BUCKET_NAME = aws_s3_bucket.wp_static.bucket

    AUTH_KEY         = random_password.wp_salt.result
    SECURE_AUTH_KEY  = random_password.wp_salt.result
    LOGGED_IN_KEY    = random_password.wp_salt.result
    NONCE_KEY        = random_password.wp_salt.result
    AUTH_SALT        = random_password.wp_salt.result
    SECURE_AUTH_SALT = random_password.wp_salt.result
    LOGGED_IN_SALT   = random_password.wp_salt.result
    NONCE_SALT       = random_password.wp_salt.result

    WP_DEBUG = var.enable_debug

    WP_TITLE          = var.title
    WP_ADMIN_USER     = var.admin_user
    WP_ADMIN_PASSWORD = random_password.wp_admin_password.result
    WP_ADMIN_EMAIL    = var.admin_email

    EFS_ID = aws_efs_file_system.wp_efs.id
  }
}

data "aws_iam_policy_document" "wp_assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "wp_access_bucket_policy" {
  statement {
    effect = "Allow"

    actions = [
      "s3:*",
    ]

    resources = [
      aws_s3_bucket.wp_static.arn,
      "${aws_s3_bucket.wp_static.arn}/*",
    ]
  }
}

resource "aws_iam_role" "wp_node_role" {
  name               = "${var.name}-${var.environment}-wp-node-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.wp_assume_role_policy.json

  tags = {
    Name        = "${var.name}-${var.environment}-wp-node-role"
    Environment = "${var.environment}"
  }
}

resource "aws_iam_role_policy" "wp_attach_bucket_permission_to_role" {
  name   = "${var.name}-enable-bucket-access"
  role   = aws_iam_role.wp_node_role.id
  policy = data.aws_iam_policy_document.wp_access_bucket_policy.json
}

resource "aws_iam_instance_profile" "wp_node_profile" {
  name = "${var.name}-${var.environment}-wp-node-profile"
  role = aws_iam_role.wp_node_role.name

  tags = {
    Name        = "${var.name}-${var.environment}-wp-node-profile"
    Environment = "${var.environment}"
  }
}

resource "aws_launch_template" "wp_lt" {
  name_prefix   = var.name
  image_id      = var.cluster.instance_image_id
  instance_type = var.cluster.instance_type
  key_name      = var.cluster.key_name

  iam_instance_profile {
    arn = aws_iam_instance_profile.wp_node_profile.arn
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.wp_ec2_sg.id]
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.name}"
    }
  }

  user_data = data.template_file.startup_script.rendered

  tags = {
    Name        = "${var.name}-${var.environment}-wp-lt"
    Environment = "${var.environment}"
  }
}

resource "aws_autoscaling_group" "wp_as" {
  name = var.name

  min_size         = var.cluster.min_size
  max_size         = var.cluster.max_size
  desired_capacity = var.cluster.desired_size

  vpc_zone_identifier = var.cluster.private_subnets

  target_group_arns = [aws_lb_target_group.wp_alb_tg.arn]

  launch_template {
    id      = aws_launch_template.wp_lt.id
    version = "$Latest"
  }
}

resource "aws_efs_file_system" "wp_efs" {
  creation_token = var.name

  tags = {
    Name        = "${var.name}-${var.environment}-wp-efs"
    Environment = "${var.environment}"
  }
}

resource "aws_security_group" "wp_efs_sg" {
  name   = "${var.name}-efs-sg"
  vpc_id = var.vpc_id

  ingress {
    description     = "Allow efs inbound from VM security group"
    protocol        = "tcp"
    from_port       = 2049
    to_port         = 2049
    security_groups = [aws_security_group.wp_ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.name}-${var.environment}-efs-sg"
    Environment = "${var.environment}"
  }
}

resource "aws_efs_mount_target" "wp_efs_mount_target" {
  count           = length(var.cluster.private_subnets)
  file_system_id  = aws_efs_file_system.wp_efs.id
  subnet_id       = element(var.cluster.private_subnets, count.index)
  security_groups = [aws_security_group.wp_efs_sg.id]
}
