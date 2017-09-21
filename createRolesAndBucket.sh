#!/bin/bash
# Run this script to one timeoff to create 'CodeDeployServiceRole' &
# 'fliSinatra-EC2-Instance-Profile'
# This task must be done before run buildImage.sh

# Get configuration variables
source rolesAndBucket.conf

# Create s3 bucket
echo "Creating s3 bucket"
aws s3api create-bucket --bucket $s3BucketName --region $region --create-bucket-configuration LocationConstraint=$region

# Create CodeDeployServiceRole
echo "Creating CodeDeployServiceRole"
aws iam create-role --role-name $codeDeployServiceRoleName --assume-role-policy-document file://CodeDeployServiceRole-Trust.json

aws iam attach-role-policy --role-name $codeDeployServiceRoleName --policy-arn arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole

# Create fliSinatraInstanceProfile
echo "Creating Instance Profile"
aws iam create-role --role-name fliSinatraEC2S3 --assume-role-policy-document file://fliSinatra-EC2-Trust.json

aws iam put-role-policy --role-name fliSinatraEC2S3 --policy-name fliSinatra-EC2-S3-Permissions --policy-document file://fliSinatra-EC2-S3-Permissions.json

aws iam create-instance-profile --instance-profile-name $instanceProfileName

aws iam add-role-to-instance-profile --instance-profile-name $instanceProfileName --role-name fliSinatraEC2S3

exit 0
