resource "aws_ecr_repository" "skills_ecr_product" {
  name = "skills-ecr-product"
  force_delete = true
}
