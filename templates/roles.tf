## Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved
##
### SPDX-License-Identifier: MIT-0

locals {
  iam_role_name       = "${var.app_prefix}-EKSRunTaskSyncExecutionRole"
  iam_policy_name     = "FargateTaskNotificationAccessPolicy"
  iam_task_role_policy_name = "${var.app_prefix}-EKS-Task-Role-Policy"
  iam_workernode_role_policy_name = "${var.app_prefix}-EKS-WorkerNodes-Role-Policy"
  iam_fargate_sa_role_policy_name = "${var.app_prefix}-EKS-SA-Role-Policy"
}


####################################################################
## Below section has roles for 
## Fargate Pod Exection Role, AWS Fargate Profile
## Service Account IAM Role for the POD
####################################################################


resource "aws_iam_role" "eks_stepfunction_iam_fargate_role" {
  name = "AmazonEKSFargatePodExecutionRole"
 
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "eks-fargate-pods.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "eks_stepfunction_AmazonEKSFargatePodExecutionRolePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.eks_stepfunction_iam_fargate_role.name
}

resource "aws_iam_role" "eks_stepfunction_iam_sa_role" {
  name               = "eks_stepfunction_iam_sa_role"
  assume_role_policy = "${data.aws_iam_policy_document.eks_stepfunction_fargate_oidc_assume_policy_document.json}"
}

data "aws_iam_policy_document" "eks_stepfunction_fargate_oidc_assume_policy_document" {
  
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    principals {
      type        = "Federated"
      identifiers = ["${module.eks.oidc_provider_arn}"]
    }
    
    condition {
      test     = "StringLike"
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub"

      values = [
         "system:serviceaccount:${var.eks_app_namespace}:${local.eks_service_account_name}"
      ]
    }

    condition {
      test     = "StringLike"
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:aud"

      values = [
         "sts.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role_policy" "eks_stepfunction_iam_sa_role_attachment_policy" {
  name = "${local.iam_fargate_sa_role_policy_name}"
  role = aws_iam_role.eks_stepfunction_iam_sa_role.name
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
            "Effect": "Allow",
            "Action": [
                "s3:get*",
                "s3:list*"
            ],
            "Resource": [
                "arn:aws:s3:::${aws_s3_bucket.eks_stepfunction_source_s3bucket.bucket}",
                "arn:aws:s3:::${aws_s3_bucket.eks_stepfunction_source_s3bucket.bucket}/*"
            ]
        },
         {
            "Effect": "Allow",
            "Action": [
                "kinesis:DescribeStream",
                "kinesis:GetRecords",
                "kinesis:PutRecords"

            ],
            "Resource": [
                "${aws_kinesis_stream.eks_stepfunction_kinesis_stream.arn}"
            ]
        }
    ]
}
EOF
}

resource "aws_eks_fargate_profile" "eks_stepfunction_eks_fargate_profile" {

  depends_on = [module.eks]

  cluster_name           = "${var.eks_cluster_name}"
  fargate_profile_name   = "fg_profile"
  pod_execution_role_arn = aws_iam_role.eks_stepfunction_iam_fargate_role.arn
  subnet_ids             = module.vpc.private_subnets
  selector {
    namespace =  "${var.eks_app_namespace}"

    labels = {
      name = "${var.eks_app_name}"
    }
  }
  
}

resource "aws_eks_fargate_profile" "coredns" {
  depends_on = [module.eks]
  
  cluster_name           = "${var.eks_cluster_name}"
  fargate_profile_name   = "coredns"
  pod_execution_role_arn = aws_iam_role.eks_stepfunction_iam_fargate_role.arn
  subnet_ids             = module.vpc.private_subnets

  selector {
    labels = {
      "k8s-app" = "kube-dns"
    }
    namespace = "kube-system"
  }
}


####################################################################
## Below section has roles for Step Functions to trigger the EKS Job
####################################################################

resource "aws_iam_role" "eks_stepfunction_role" {
  name               = "${local.iam_role_name}"
  assume_role_policy = "${data.aws_iam_policy_document.eks_stepfunction_policy_document.json}"
}

data "aws_iam_policy_document" "eks_stepfunction_policy_document" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "eks_stepfunction_policy" {
  name = "${local.iam_policy_name}"
  role = "${aws_iam_role.eks_stepfunction_role.id}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "iam:GetRole",
                "iam:PassRole"
            ],
            "Resource": "*"
        },
        {
            "Action": [
                "sns:Publish"
            ],
            "Resource": [
                "${aws_sns_topic.eks_stepfunction_sns.arn}"
            ],
            "Effect": "Allow"
        },
        {
            "Action": [
                "eks:run*",
                "eks:call"
            ],
            "Resource": [
              "${module.eks.cluster_arn}"
            ],
            "Effect": "Allow"
        }
    ]
}
EOF
}

####################################################################
## Below section has roles for Step Functions to trigger the EKS Job
####################################################################
 
resource "aws_iam_role" "eks_firehose_delivery_role" {
  name = "${var.app_prefix}-firehose-delivery-Role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "eks_delivery_role_kinesis_attachment" {
  role       = "${aws_iam_role.eks_firehose_delivery_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonKinesisReadOnlyAccess"
}


resource "aws_iam_role_policy" "eks_firehose_delivery_role_policy" {
  name = "${local.iam_policy_name}"
  role = "${aws_iam_role.eks_firehose_delivery_role.id}"
  
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:put*"
            ],
            "Resource": [
                "arn:aws:s3:::${aws_s3_bucket.eks_stepfunction_target_s3bucket.bucket}",
                "arn:aws:s3:::${aws_s3_bucket.eks_stepfunction_target_s3bucket.bucket}/*"
            ]
        },
         {
            "Effect": "Allow",
            "Action": [
                "kinesis:DescribeStream",
                "kinesis:GetRecords"
            ],
            "Resource": [
                "${aws_kinesis_stream.eks_stepfunction_kinesis_stream.arn}"
            ]
        }
    ]
}
EOF
}


resource "aws_iam_role" "eks_stepfunction_vpc_flow_log_role" {
  name = "eks_stepfunction_vpc_flow_log_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "eks_stepfunction_vpc_flow_log_role_policy" {
  name = "eks_stepfunction_vpc_flow_log_role_policy"
  role = aws_iam_role.eks_stepfunction_vpc_flow_log_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}


####################################################################
## Below section has role attachment for Fargate Role to log cloudwatch logs
####################################################################

resource "aws_iam_role_policy" "eks_stepfunction_fargate_role_attachment_policy" {
  name = "${local.iam_workernode_role_policy_name}"
  role = aws_iam_role.eks_stepfunction_iam_fargate_role.name
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents"
        ],
        "Resource": "*"
      }
    ]
}
EOF
}

