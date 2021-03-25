## Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved
##
### SPDX-License-Identifier: MIT-0

resource "aws_flow_log" "s3_handler_flow_logs" {
  iam_role_arn    = aws_iam_role.eks_stepfunction_vpc_flow_log_role.arn
  log_destination = aws_cloudwatch_log_group.eks_stepfunction_vpc_flow_log_group.arn
  traffic_type    = "REJECT"
  vpc_id          = module.vpc.vpc_id
  max_aggregation_interval = 600
}