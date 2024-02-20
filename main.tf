
provider "aws" {
 region = "us-east-1" 
}

terraform {
  backend "s3" {
    bucket = "tfstate-ecr0213"
    key    = "terraform.tfstate"
    region = "us-east-1"

    dynamodb_table = "StateLockEcr"
  }
}


resource "aws_ecr_repository" "repository" {
  name = "python-ecr-repo"
}

resource "aws_ecr_lifecycle_policy" "lifecycle_policy" {
  repository = aws_ecr_repository.repository.name

  policy = <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "keep last 3 images",
      "selection": {
        "tagStatus": "tagged",
        "tagPatternList": [
          "v0.*"
        ],
        "countType": "imageCountMoreThan",
        "countNumber": 3
      },
      "action": {
        "type": "expire"
      }
    },
    {
      "rulePriority": 2,
      "description": "remove untagged",
      "selection": {
        "tagStatus": "untagged",
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 1
      },
      "action": {
        "type": "expire"
      }
    },
    {
      "rulePriority": 3,
      "description": "remove snapshots",
      "selection": {
        "tagStatus": "tagged",
        "tagPatternList": [
          "*snapshot"
        ],
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 7
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF
}
