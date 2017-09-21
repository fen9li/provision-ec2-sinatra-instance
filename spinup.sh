#!/bin/bash
# spinup.sh - spin up a sinatra web server upon AWS ec2 instance
# Usage: cd to the directory containing this script and
#        give the command "./spinup.sh"

# Cleanup any resources left from previous build image runs (prevents error msgs.)
./cleanupSpinup.sh

source rolesAndBucket.conf
source spinup.conf

# Create zip archive
echo "Updating spinupApp.zip locally"
rm spinupApp.zip
cd spinupApp
rm -Rf "$githubRepoName"
git clone "$githubRepo"
cd "$githubRepoName"
rm -Rf .git
cd ..
zip -qr ../spinupApp.zip *
cd ..

# Delete possible old version archive and upload new version to S3
echo "Updating spinupApp.zip in s3 bucket"
aws s3 rm "s3://$s3BucketName/spinupApp.zip"
aws s3 cp spinupApp.zip "s3://$s3BucketName"

# Generate UUID
UUID=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`

# Run CloudFormation to create the instance
templatebody="file://`pwd`/cfTemplate.json"

#DEBUG aws cloudformation validate-template --template-body $templatebody

echo "Running cloudformation to create stack and provision ec2 instance"
aws cloudformation create-stack --stack-name $cfStackName --template-body $templatebody --parameters ParameterKey=IamInstanceProfileName,ParameterValue=$instanceProfileName ParameterKey=UUID,ParameterValue=$UUID ParameterKey=SSHLocation,ParameterValue=$SSHLocation ParameterKey=ImageId,ParameterValue=$imageId

echo "Sleeping 5 minutes to allow instance to start"
./countdownTimer.sh 300

# Run CodeDeploy to create a CodeDeploy Application for fliSinatraBuildImage
echo "Starting CodeDeploy operations"
aws deploy create-application --application-name $cdAppName

# Run CodeDeploy to create a CodeDeploy DeploymentGroup for the instances
aws deploy create-deployment-group --application-name $cdAppName --deployment-group-name $cdDeployGroupName --ec2-tag-filters Key=UUID,Value=$UUID,Type=KEY_AND_VALUE --service-role-arn arn:aws:iam::810636937332:role/CodeDeployServiceRole

# Run CodeDeploy to create a CodeDeploy Deployment Configuration for the instances
aws deploy create-deployment-config --deployment-config-name $cdDeploymentConfigName --minimum-healthy-hosts type=HOST_COUNT,value=0

# Run CodeDeploy to create a CodeDeploy Deployment for this revision of fliSinatra
aws deploy create-deployment --application-name $cdAppName --deployment-config-name $cdDeploymentConfigName --deployment-group-name $cdDeployGroupName --description "$cdDeploymentDescription" --s3-location bucket=$s3BucketName,bundleType=zip,key=spinupApp.zip

echo "Sleep 20 minutes to allow software installing upon this instance."
pwd
ls -l countdownTimer.sh
./countdownTimer.sh 1200

PublicIpAddress=`aws ec2 describe-instances --filters "Name=tag:UUID,Values=$UUID" --query "Reservations[].Instances[].PublicIpAddress" --output text`

# Output result
echo "A new sinatra web server has been spinned up upon an AWS ec2 instance. To test it, enter http://$PublicIpAddress/ in your web browser... and you should see a Hello World message ..."
