# Subnet groups use DB-only private subnets
resource "aws_db_subnet_group" "a" {
  name       = "${var.project_name}-a-dbsub"
  subnet_ids = [for s in aws_subnet.a_private_db : s.id]
}
resource "aws_db_subnet_group" "b" {
  provider   = aws.dr
  name       = "${var.project_name}-b-dbsub"
  subnet_ids = [for s in aws_subnet.b_private_db : s.id]
}

# Primary DB (Region A)
resource "aws_db_instance" "primary" {
  identifier              = "${var.project_name}-mysql-a"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  db_name                 = "appdb"
  username                = var.db_username
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.a.name
  vpc_security_group_ids  = [aws_security_group.a_db.id]
  multi_az                = true
  publicly_accessible     = false
  backup_retention_period = 7
  skip_final_snapshot     = true
}

# Cross-region replica (Region B)
resource "aws_db_instance" "replica" {
  provider               = aws.dr
  identifier             = "${var.project_name}-mysql-b"
  engine                 = "mysql"
  instance_class         = "db.t3.micro"
  replicate_source_db    = aws_db_instance.primary.arn
  db_subnet_group_name   = aws_db_subnet_group.b.name
  vpc_security_group_ids = [aws_security_group.b_db.id]
  publicly_accessible    = false
  skip_final_snapshot    = true
}
