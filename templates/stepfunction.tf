## Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved
##
### SPDX-License-Identifier: MIT-0

##################################################
# AWS Step Functions - Start Fargate Task On success notify SNS
##################################################

locals {
  eks_cluster_name = "${var.eks_cluster_name}"
  ecr_repo    = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${var.app_prefix}-repo"
  eks_cluster_cert_authority =  module.eks.cluster_certificate_authority_data
  eks_cluster_api = module.eks.cluster_endpoint
  s3_bucket   = "${aws_s3_bucket.eks_stepfunction_source_s3bucket.bucket}" 
  stream_name = "${aws_kinesis_stream.eks_stepfunction_kinesis_stream.arn}"
  region      = "${data.aws_region.current.name}"
  process_s3  = "${var.process_s3}"
  log_group   = "${aws_cloudwatch_log_group.eks_stepfunction_container_cloudwatch_loggroup.name}"
}

resource "aws_sfn_state_machine" "eks_stepfunction_state_machine" {
  name     = "${var.app_prefix}-EKSTaskStateMachine"
  role_arn = "${aws_iam_role.eks_stepfunction_role.arn}"

  definition = <<DEFINITION
{
  "Comment": "Application Process using AWS Step Functions and Amazon ECS & AWS Fargate",
  "StartAt": "Run a job on EKS",
  "TimeoutSeconds": 3600,
  "States": {
    "Run a job on EKS": {
      "Type": "Task",
      "Resource": "arn:aws:states:::eks:runJob.sync",
      "Parameters": {
        "Namespace": "${var.eks_app_namespace}",
        "ClusterName": "${local.eks_cluster_name}",
        "CertificateAuthority": "${local.eks_cluster_cert_authority}",
        "Endpoint": "${local.eks_cluster_api}",
        "LogOptions": {
          "RetrieveLogs": "true"
        },
        "Job": {
          "apiVersion": "batch/v1",
          "kind": "Job",
          "metadata": {
            "name": "${var.eks_app_name}",
            "namespace": "${var.eks_app_namespace}",
            "labels": {
              "app": "${var.eks_app_name}-app"
            }
          },
          "waitForCompletion": "true",
          "spec": {
            "template": {
              "metadata": {
                "labels": {
                  "name": "${var.eks_app_name}"
                }
              },
              "spec": {
                "serviceAccountName": "${local.eks_service_account_name}",
                "restartPolicy": "Never",
                "containers": [
                  {
                    "name": "${var.eks_app_name}-app",
                    "image": "${local.ecr_repo}",
                    "env": [{
                      "name": "REGION",
                      "value": "${local.region}"
                    },
                    {
                      "name": "S3_BUCKET",
                      "value": "${aws_s3_bucket.eks_stepfunction_source_s3bucket.bucket}"
                    },
                    {
                      "name": "STREAM_NAME",
                      "value": "${aws_kinesis_stream.eks_stepfunction_kinesis_stream.name}"
                    },
                    {
                      "name": "PROCESS_S3",
                      "value": "${local.process_s3}"
                    }],
                     "resources": {
                        "limits": {
                            "cpu": "500m",
                            "memory": "256Mi"
                          },
                          "requests": {
                            "cpu": "500m",
                            "memory": "256Mi"
                          }
                        }
                  }
                ]
              }
            }
          }
        }
      },
      "Next": "Delete job",
      "Catch": [
          {
            "ErrorEquals": [ "States.ALL" ],
            "Next": "Notify Failure"
          }
      ]
    },
     "Delete job": {
      "Type": "Task",
      "Resource": "arn:aws:states:::eks:call",
      "Parameters": {
        "ClusterName": "${local.eks_cluster_name}",
        "CertificateAuthority": "${local.eks_cluster_cert_authority}",
        "Endpoint": "${local.eks_cluster_api}",
        "Method": "DELETE",
        "Path": "/apis/batch/v1/namespaces/${var.eks_app_namespace}/jobs/${var.eks_app_name}"
      },
      "ResultSelector": {
        "status.$": "$.ResponseBody.status"
      },
      "ResultPath": "$.DeleteJobResult",
      "Next": "Notify Success",
      "Catch": [
          {
            "ErrorEquals": [ "States.ALL" ],
            "Next": "Notify Failure"
          }
      ]
    },
    "Notify Success": {
      "Type": "Task",
      "Resource": "arn:aws:states:::sns:publish",
      "Parameters": {
        "Message": "AWS Fargate Task started by Step Functions succeeded",
        "TopicArn": "${aws_sns_topic.eks_stepfunction_sns.arn}"
      },
      "End": true
    },
    "Notify Failure": {
      "Type": "Task",
      "Resource": "arn:aws:states:::sns:publish",
      "Parameters": {
        "Message": "AWS Fargate Task started by Step Functions failed",
        "TopicArn": "${aws_sns_topic.eks_stepfunction_sns.arn}"
      },
      "End": true
    }
  }
}
DEFINITION
}

