## Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved
##
### SPDX-License-Identifier: MIT-0

resource "aws_s3_bucket" "eks_stepfunction_source_s3bucket" {
  bucket =  "${var.app_prefix}-${var.stage_name}-source-bucket-${data.aws_caller_identity.current.account_id}"
  acl    = "private"

  tags = {
    Name        = "${var.app_prefix}-source-s3"
    Environment = "${var.stage_name}"
  }
}

resource "aws_s3_bucket" "eks_stepfunction_target_s3bucket" {
  bucket =  "${var.app_prefix}-${var.stage_name}-target-bucket-${data.aws_caller_identity.current.account_id}"
  acl    = "private"

  tags = {
    Name        = "${var.app_prefix}-target-s3"
    Environment = "${var.stage_name}"
  }
}

resource "aws_vpc_endpoint" "eks_stepfunction_s3_vpc_endpoint" {
  vpc_id       = module.vpc.vpc_id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
  
  tags = {
    Environment = "${var.app_prefix}-s3-vpc-endpoint"
  }
}

resource "aws_vpc_endpoint_route_table_association" "Private_route_table_association_1" {
  route_table_id  = module.vpc.private_route_table_ids[0]
  vpc_endpoint_id = aws_vpc_endpoint.eks_stepfunction_s3_vpc_endpoint.id
}
resource "aws_vpc_endpoint_route_table_association" "Private_route_table_association_2" {
  route_table_id  = module.vpc.private_route_table_ids[1]
  vpc_endpoint_id = aws_vpc_endpoint.eks_stepfunction_s3_vpc_endpoint.id
}