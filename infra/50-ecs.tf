resource "aws_ecs_cluster" "cluster" {
  name = "skills-cluster"
}

resource "aws_ecs_cluster_capacity_providers" "workers" {
  cluster_name = aws_ecs_cluster.cluster.name
  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

