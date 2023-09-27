resource "local_file" "appspect_stress" {
  filename = "../src/stress/appspec.yaml"
  content  = <<EOF
version: 0.0
Resources:
  - TargetService:
      Type: AWS::ECS::Service
      Properties:
        TaskDefinition: "${aws_ecs_task_definition.td_stress.arn_without_revision}"
        LoadBalancerInfo: 
          ContainerName: "app" 
          ContainerPort: 8080
EOF
}
