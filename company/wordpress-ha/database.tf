resource "random_password" "wp_db_password" {
  length           = var.db.pass_length
  special          = var.db.pass_special
  override_special = var.db.pass_override_special
}

resource "aws_secretsmanager_secret" "wp_db_password_sm" {
  name = "${var.name}-${var.environment}-db-main-pass-sm"

  tags = {
    Name        = "${var.name}-${var.environment}-db-main-pass-sm"
    Environment = "${var.environment}"
  }
}

resource "aws_secretsmanager_secret_version" "wp_db_password_sm_version" {
  secret_id     = aws_secretsmanager_secret.wp_db_password_sm.id
  secret_string = random_password.wp_db_password.result
}

resource "aws_db_subnet_group" "wp_db_subnet_group" {
  name       = "${var.name}-db-sn-group"
  subnet_ids = var.db.subnets

  tags = {
    Name        = "${var.name}-${var.environment}-db-sng"
    Environment = "${var.environment}"
  }
}

data "aws_subnet" "wp_private_subnets" {
  count = length(var.cluster.private_subnets)
  id    = element(var.cluster.private_subnets, count.index)
}

resource "aws_security_group" "wp_db_sg" {
  name   = "${var.name}-${var.environment}-db-sg"
  vpc_id = var.vpc_id

  ingress {
    description = "Allow inbound from private subnets"
    protocol    = "tcp"
    from_port   = var.db.port
    to_port     = var.db.port
    cidr_blocks = data.aws_subnet.wp_private_subnets[*].cidr_block
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.name}-${var.environment}-db-sg"
    Environment = "${var.environment}"
  }
}

resource "aws_db_instance" "wp_db_primary" {
  identifier                   = "${var.name}-${var.environment}-db"
  db_name                      = replace(var.name, "-", "")
  allocated_storage            = var.db.allocated_storage
  max_allocated_storage        = var.db.max_allocated_storage
  engine                       = var.db.engine
  engine_version               = var.db.engine_version
  instance_class               = var.db.primary_instance_class
  username                     = var.db.username
  db_subnet_group_name         = aws_db_subnet_group.wp_db_subnet_group.name
  vpc_security_group_ids       = [aws_security_group.wp_db_sg.id]
  password                     = random_password.wp_db_password.result
  backup_retention_period      = var.db.backup_retention_period
  backup_window                = var.db.backup_window
  maintenance_window           = var.db.maintenance_window
  skip_final_snapshot          = var.db.skip_final_snapshot
  multi_az                     = var.db.enable_multi_az
  performance_insights_enabled = var.db.enable_performance_insights
  apply_immediately            = var.db.enable_apply_immediately

  tags = {
    Name        = "${var.name}-${var.environment}-db"
    Environment = "${var.environment}"
  }
}

