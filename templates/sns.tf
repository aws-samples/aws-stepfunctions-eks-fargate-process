## Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved
##
### SPDX-License-Identifier: MIT-0

resource "aws_sns_topic" "eks_stepfunction_sns" {
  name = "${var.app_prefix}-SNSTopic"
}