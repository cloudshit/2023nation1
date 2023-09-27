resource "aws_lb" "alb" {
  name            = "skills-alb"
  subnets         = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id,
    aws_subnet.public_c.id
  ]
  internal = false
  security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.id
  port              = "80"
  protocol          = "HTTP"


  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "403 page error"
      status_code  = "403"
    }
  }
}

resource "aws_lb_listener_rule" "stress" {
  listener_arn = aws_lb_listener.listener.arn
  priority     = 100

  action {
    type = "forward"

    forward {
      target_group {
        arn = aws_lb_target_group.tg1_stress.arn
        weight = 1
      }

      target_group {
        arn = aws_lb_target_group.tg2_stress.arn
        weight = 0
      }
    }
  }

  condition {
    path_pattern {
      values = ["/v1/stress/*"]
    }
  }
}

resource "aws_lb_listener_rule" "product" {
  listener_arn = aws_lb_listener.listener.arn
  priority     = 200

  action {
    type = "forward"

    forward {
      target_group {
        arn = aws_lb_target_group.tg1_product.arn
        weight = 1
      }

      target_group {
        arn = aws_lb_target_group.tg2_product.arn
        weight = 0
      }
    }
  }

  condition {
    path_pattern {
      values = ["/v1/product/*"]
    }
  }
}
