resource "aws_lb_target_group" "tg1_product" {
  name        = "skills-tg1-product"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  deregistration_delay = 0

  health_check {
    path = "/healthcheck"
    matcher = "200"
    timeout = 2
    interval = 5
    unhealthy_threshold = 2
    healthy_threshold = 2
  }
}

resource "aws_lb_target_group" "tg2_product" {
  name        = "skills-tg2-product"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  deregistration_delay = 0

  health_check {
    path = "/healthcheck"
    matcher = "200"
    timeout = 2
    interval = 5
    unhealthy_threshold = 2
    healthy_threshold = 2
  }
}
