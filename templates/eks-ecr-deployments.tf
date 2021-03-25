## Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved
##
### SPDX-License-Identifier: MIT-0

locals {
  eks_service_account_name       = "${var.eks_app_name}-service-account"
}

resource "kubernetes_namespace" "s3_handler" {
  metadata {
    name = "aws-observability"
    labels = {
      aws-observability = "enabled"
    }
  }
}

data "template_file" "yaml_script" {
  template = "${file("${path.module}/configmap_data_output.yml")}"
  vars = {
    region = "${data.aws_region.current.name}"
    cw_log_group = "${aws_cloudwatch_log_group.eks_stepfunction_container_cloudwatch_loggroup.name}"
    cw_log_stream = "${aws_cloudwatch_log_stream.eks_stepfunction_container_cloudwatch_logstream.name}"
  }
}

resource "kubernetes_config_map" "s3_handler" {
  metadata {
    name = "aws-logging"
    namespace = "aws-observability"
  }
  data = {
     "output.conf" = "${data.template_file.yaml_script.rendered}"
  }
}

resource "kubernetes_namespace" "s3-handler-namespace" {
  metadata {
    labels = {
      "name" = "${var.eks_app_name}"
    }

    name = "${var.eks_app_namespace}"
  }
}

resource "kubernetes_service_account" "s3-handler-service-account" {
  automount_service_account_token = true
  metadata {
    name = "${local.eks_service_account_name}"
    namespace= "${var.eks_app_namespace}"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.eks_stepfunction_iam_sa_role.arn
    }
    labels = {
      "name" = "${var.eks_app_name}"
    }
  }
}
resource "kubernetes_cluster_role_binding" "s3-handler-role-binding" {
  metadata {
    name = format("%s-%s-role-binding", local.eks_service_account_name, var.eks_app_name)
    labels = {
      name = format("%s-%s-role-binding", local.eks_service_account_name, var.eks_app_name)
    }
  }

  subject {
    kind = "ServiceAccount"
    name = "${local.eks_service_account_name}"
    namespace= "${var.eks_app_namespace}"
  }

  role_ref {
    kind = "ClusterRole"
    name = "system:auth-delegator"
    api_group = "rbac.authorization.k8s.io"
  }
}
