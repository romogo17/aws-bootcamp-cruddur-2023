
resource "aws_db_instance" "cruddur" {
  identifier                   = "cruddur-db-instance"
  db_name                      = "cruddur"
  instance_class               = "db.t3.micro"
  engine                       = "postgres"
  engine_version               = "14.6"
  username                     = var.db_username
  password                     = var.db_password
  allocated_storage            = 20
  port                         = 5432
  publicly_accessible          = true
  storage_encrypted            = true
  skip_final_snapshot          = true
  multi_az                     = false
  performance_insights_enabled = false
  deletion_protection          = false
  vpc_security_group_ids       = [aws_security_group.rds.id]
}


resource "aws_security_group" "rds" {
  name        = "cruddur-rds-sg"
  description = "Security group for Cruddur RDS DB"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.cruddur_ecs_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_default_security_group" "default" {
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
