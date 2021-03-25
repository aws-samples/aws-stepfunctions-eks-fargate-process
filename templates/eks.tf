## Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved
##
### SPDX-License-Identifier: MIT-0

module "eks" {
  source                            = "terraform-aws-modules/eks/aws"
  cluster_name                      = "${var.eks_cluster_name}"
  cluster_version                   = "1.19"
  subnets                           = module.vpc.private_subnets
  cluster_create_timeout            = "30m"
  cluster_endpoint_private_access   = true 
  vpc_id                            = module.vpc.vpc_id
  enable_irsa                       = true
  wait_for_cluster_cmd              = "until curl -k -s $ENDPOINT/healthz >/dev/null; do sleep 4; done"
  
  map_roles = [{
      rolearn  = "${aws_iam_role.eks_stepfunction_role.arn}"
      username = "sfn-fg-role-user"
      groups   = ["system:masters"]
    },
    {
      rolearn  = "${aws_iam_role.eks_stepfunction_iam_sa_role.arn}"
      username = "sa-iam-role-user"
      groups   = ["system:masters"]
    }]
}


