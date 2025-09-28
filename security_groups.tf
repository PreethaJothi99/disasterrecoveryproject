# Primary
resource "aws_security_group" "a_alb" {
  name   = "${var.project_name}-a-alb"
  vpc_id = aws_vpc.a.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "a_app" {
  name   = "${var.project_name}-a-app"
  vpc_id = aws_vpc.a.id
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.a_alb.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "a_db"  {
  name   = "${var.project_name}-a-db"
  vpc_id = aws_vpc.a.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group_rule" "a_db_ingress" {
  type = "ingress"
  security_group_id        = aws_security_group.a_db.id
  from_port = 3306
  to_port   = 3306
  protocol  = "tcp"
  source_security_group_id = aws_security_group.a_app.id
}

# Secondary
resource "aws_security_group" "b_alb" {
  provider = aws.dr
  name   = "${var.project_name}-b-alb"
  vpc_id = aws_vpc.b.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "b_app" {
  provider = aws.dr
  name   = "${var.project_name}-b-app"
  vpc_id = aws_vpc.b.id
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.b_alb.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "b_db"  {
  provider = aws.dr
  name   = "${var.project_name}-b-db"
  vpc_id = aws_vpc.b.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group_rule" "b_db_ingress" {
  provider = aws.dr
  type = "ingress"
  security_group_id        = aws_security_group.b_db.id
  from_port = 3306
  to_port   = 3306
  protocol  = "tcp"
  source_security_group_id = aws_security_group.b_app.id
}
