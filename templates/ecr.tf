## Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved
##
### SPDX-License-Identifier: MIT-0

resource "aws_ecr_repository" "eks_stepfunction_ecr_repo" {
  name                 = "${var.app_prefix}-repo"
  
  tags = {
    Name = "${var.app_prefix}-ecr-repo"
  }
}