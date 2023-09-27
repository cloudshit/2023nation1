resource "aws_appautoscaling_target" "tg_product" {
  max_capacity = 32
  min_capacity = 3
  resource_id = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.svc_product.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace = "ecs"
}

resource "aws_appautoscaling_policy" "memory_product" {
  name               = "memory"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.tg_product.resource_id
  scalable_dimension = aws_appautoscaling_target.tg_product.scalable_dimension
  service_namespace  = aws_appautoscaling_target.tg_product.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value       = 40
  }
}

resource "aws_appautoscaling_policy" "cpu_product" {
  name = "cpu"
  policy_type = "TargetTrackingScaling"
  resource_id = aws_appautoscaling_target.tg_product.resource_id
  scalable_dimension = aws_appautoscaling_target.tg_product.scalable_dimension
  service_namespace = aws_appautoscaling_target.tg_product.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 40
  }
}
