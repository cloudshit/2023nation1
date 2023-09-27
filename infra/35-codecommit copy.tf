resource "aws_codecommit_repository" "code_product" {
  repository_name = "skills-product"
  default_branch = "upstream"
  lifecycle {
    ignore_changes = [default_branch]
  }
}
