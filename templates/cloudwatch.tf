## Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved
##
### SPDX-License-Identifier: MIT-0

resource "aws_cloudwatch_log_group" "eks_stepfunction_container_cloudwatch_loggroup" {
  name = "${var.app_prefix}-cloudwatch-log-group"

  tags = {
    Name        = "${var.app_prefix}-cloudwatch-log-group"
    Environment = "${var.stage_name}"
  }
}

resource "aws_cloudwatch_log_stream" "eks_stepfunction_container_cloudwatch_logstream" {
  name           = "${var.app_prefix}-cloudwatch-log-stream"
  log_group_name =  "${aws_cloudwatch_log_group.eks_stepfunction_container_cloudwatch_loggroup.name}"
}

resource "aws_cloudwatch_log_group" "eks_stepfunction_vpc_flow_log_group" {
   name = "${var.app_prefix}-vpcflowlog-cloudwatch-log-group"
}
