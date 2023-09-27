resource "aws_security_group" "db" {
  name        = "wsi-sg-db"
  description = "Allow database traffic"
  vpc_id      = aws_vpc.main.id

  lifecycle {
    ignore_changes = [
      ingress,
      egress
    ]
  }
}

resource "aws_db_subnet_group" "db" {
  name = "wsi-db-subnets"
  subnet_ids = [
    aws_subnet.protected_a.id,
    aws_subnet.protected_b.id,
    aws_subnet.protected_c.id
  ]
}

resource "aws_rds_cluster" "db" {
  cluster_identifier          = "wsi-mysql-cluster"
  database_name               = "product"
  availability_zones        = ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c"]
  db_subnet_group_name = aws_db_subnet_group.db.name
  master_username             = "admin"
  master_password = "password"
  vpc_security_group_ids = [aws_security_group.db.id]
  skip_final_snapshot = true
  storage_encrypted = true
  engine = "aurora-mysql"
}

resource "aws_rds_cluster_instance" "db" {
  count = 3
  cluster_identifier = aws_rds_cluster.db.id
  instance_class         = "db.r6g.large"
  identifier             = "wsi-db-${count.index}"
  engine = "aurora-mysql"
}

resource "aws_secretsmanager_secret" "db" {
  name_prefix = "product/dbcred"
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id     = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    "username" = "changeme"
    "password" = "changeme"
    "engine" =  "mysql"
    "host" = aws_rds_cluster.db.endpoint
    "port" = aws_rds_cluster.db.port
    "dbClusterIdentifier" = aws_rds_cluster.db.cluster_identifier
    "dbname" = aws_rds_cluster.db.database_name
  })
}
