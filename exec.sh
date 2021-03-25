ACCOUNT_NUMBER=<YOUR_ACCOUNT_NUMBER>
REGION=<YOUR_ACCOUNT_REGION>
INPUT_S3_BUCKET="eks-stepfunction-dev-source-bucket"
EKS_CLUSTER_NAME="eks-stepfunction-cluster"

APP_ECR_REPO_NAME=eks-stepfunction-repo
APP_ECR_REPO_URL=$ACCOUNT_NUMBER.dkr.ecr.$REGION.amazonaws.com/$APP_ECR_REPO_NAME


# Terraform infrastructure apply
cd templates
terraform init
terraform apply --auto-approve

aws eks update-kubeconfig --name $EKS_CLUSTER_NAME --region $REGION
cd ..

# Build the app Jar
mvn clean package

docker build -t example/eks-stepfunction-java-app . 
docker tag example/eks-stepfunction-java-app ${APP_ECR_REPO_URL}:latest

aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_NUMBER.dkr.ecr.$REGION.amazonaws.com
docker push ${APP_ECR_REPO_URL}:latest


#######
### PUT SAMPLE S3 For the Input S3 bucket
#######

CURRYEAR=`date +"%Y"`
CURRMONTH=`date +"%m"`
CURRDATE=`date +"%d"`

echo $CURRYEAR-$CURRMONTH-$CURRDATE

echo "Creating sample files and will load to S3"
COUNTER=0
NUMBER_OF_FILES=5

EXTN=".txt"
S3_SUB_PATH=$CURRYEAR"/"$CURRMONTH"/"$CURRDATE
echo $S3_SUB_PATH

INPUT_S3_BUCKET_PATH="s3://$INPUT_S3_BUCKET-"$ACCOUNT_NUMBER

mkdir -p samples
cd samples

while [  $COUNTER -lt $NUMBER_OF_FILES ]; do
    FILENAME="Product-"$COUNTER$EXTN
    
    
    echo "{\"productId\": $COUNTER , \"productName\": \"some Name\", \"productVersion\": \"v$COUNTER\"}" >> $FILENAME

    aws s3 --region $REGION cp $FILENAME $INPUT_S3_BUCKET_PATH/$S3_SUB_PATH/

    echo $FILENAME " samples uploaded into S3 sample bucket"
    let COUNTER=COUNTER+1 
done

cd ..

kubectl patch deployment coredns -n kube-system --type json -p='[{"op": "remove", "path": "/spec/template/metadata/annotations/eks.amazonaws.com~1compute-type"}]'

kubectl rollout restart -n kube-system deployment.apps/coredns

$SHELL