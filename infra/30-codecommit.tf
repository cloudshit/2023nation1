resource "aws_codecommit_repository" "code_stress" {
  repository_name = "skills-stress"
  default_branch = "upstream"
  lifecycle {
    ignore_changes = [default_branch]
  }
}
