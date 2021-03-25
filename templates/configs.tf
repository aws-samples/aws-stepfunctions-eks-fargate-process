## Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved
##
### SPDX-License-Identifier: MIT-0

variable "app_prefix" {
  description = "Application prefix for the AWS services that are built"
  default = "eks-stepfunction"
}

variable "aws_app_region" {
  description = "Application prefix for the AWS services that are built"
  default = "us-east-1"
}

variable "eks_cluster_name" {
  description = "EKS ClusterName"
  default = "eks-stepfunction-cluster"
}

variable "eks_app_name" {
  description = "EKS Java App Name for K8s objects"
  default = "s3-handler"
}


variable "eks_app_namespace" {
  description = "Additional AWS account numbers to add to the aws-auth configmap."
  default = "s3-handler-ns"
}

variable "stage_name" {
  default = "dev"
  type    = string
}

variable "java_source_zip_path" {
  description = "Java app"
  default = "..//target//eks-stepfunction-java-app-1.0-SNAPSHOT.jar"
}

variable "process_s3" {
  default = true
}