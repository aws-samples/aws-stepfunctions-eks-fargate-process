## Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved
##
### SPDX-License-Identifier: MIT-0

resource "aws_kinesis_stream" "eks_stepfunction_kinesis_stream" {
  name             = "${var.app_prefix}-stream"
  shard_count      = 1
  retention_period = 48

  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
  ]

  tags = {
    Name        = "${var.app_prefix}-stream"
    Environment = "${var.stage_name}"
  }
}

resource "aws_kinesis_firehose_delivery_stream" "eks_stepfunction_kinesis_firehosedelivery_stream" {
  name        = "${var.app_prefix}-firehose-delivery-stream"
  destination = "s3"

  kinesis_source_configuration {
    role_arn   = "${aws_iam_role.eks_firehose_delivery_role.arn}"
    kinesis_stream_arn = "${aws_kinesis_stream.eks_stepfunction_kinesis_stream.arn}"
  }
  s3_configuration {
    role_arn   = "${aws_iam_role.eks_firehose_delivery_role.arn}"
    bucket_arn = "${aws_s3_bucket.eks_stepfunction_target_s3bucket.arn}"
    buffer_interval = 60
    cloudwatch_logging_options {
      enabled = true
      log_group_name = "${aws_cloudwatch_log_group.eks_stepfunction_container_cloudwatch_loggroup.name}"
      log_stream_name = "${aws_cloudwatch_log_stream.eks_stepfunction_container_cloudwatch_logstream.name}"
    }
  }
}