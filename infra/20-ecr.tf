resource "aws_ecr_repository" "skills_ecr_stress" {
  name = "skills-ecr-stress"
  force_delete = true
}
