ACCOUNT_NUMBER=<YOUR_ACCOUNT_NUMBER>
REGION=<YOUR_ACCOUNT_REGION>

SOURCE_S3_BUCKET="eks-stepfunction-dev-source-bucket"
TARGET_S3_BUCKET="eks-stepfunction-dev-target-bucket"
ECR_REPO_NAME="eks-stepfunction-repo"

aws ecr batch-delete-image --repository-name $ECR_REPO_NAME --image-ids imageTag=latest

aws ecr batch-delete-image --repository-name $ECR_REPO_NAME --image-ids imageTag=untagged

aws s3 rm s3://$SOURCE_S3_BUCKET-$ACCOUNT_NUMBER --recursive
aws s3 rm s3://$TARGET_S3_BUCKET-$ACCOUNT_NUMBER --recursive

cd templates
terraform destroy --auto-approve
cd ..

cd samples
rm Product*.txt

cd ..

$SHELL