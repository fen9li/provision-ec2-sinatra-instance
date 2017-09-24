#!/bin/bash

# Run this script to delete:
# s3 bucket
# CodeDeployServiceRole
# fliSinatra-EC2-Instance-Profile

# Get configuration variables
source spinup.conf

# Delete CodeDeployServiceRole
echo "Detach CodeDeployServiceRole policy"
aws iam detach-role-policy --role-name $codeDeployServiceRoleName --policy-arn arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole
echo "Delete CodeDeployServiceRole"
aws iam delete-role --role-name $codeDeployServiceRoleName

# Delete instance profile
echo "Delete fliSinatraEC2S3 role policy"
aws iam delete-role-policy --role-name fliSinatraEC2S3 --policy-name fliSinatra-EC2-S3-Permissions

echo "Remove role from instance profile"
aws iam remove-role-from-instance-profile --instance-profile-name $instanceProfileName --role-name fliSinatraEC2S3

echo "Delete fliSinatraEC2S3 role"
aws iam delete-role --role-name fliSinatraEC2S3
echo "Delete instance profile"
aws iam delete-instance-profile --instance-profile-name $instanceProfileName

# Delete s3 bucket
echo "Empty s3 bucket"
aws s3 rm "s3://$s3BucketName" --recursive

echo "Delete s3 bucket"
aws s3api delete-bucket --bucket $s3BucketName --region $region

exit 0
