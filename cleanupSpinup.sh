#!/bin/bash
# cleanupSpinup.sh - cleanup the CloudFormation stack and the CodeDeploy
#   application after a successful or failed spin up.
#   Cleanup removes all stack and CodeDeploy resources
# Usage: cd to the directory containing this script and
#       give the command "./cleanupSpinup.sh"

echo "Starting cleanup of old resources"

source rolesAndBucket.conf
source spinup.conf

# Clean up any previous CloudFormation stack (stack name: provisionSinatraWebService)
aws cloudformation delete-stack --stack-name $cfStackName

# Clean up any previous CodeDeploy artifacts (application name: spinupSinatraServer)
aws deploy delete-application --application-name $cdAppName
aws deploy delete-deployment-config --deployment-config-name $cdDeploymentConfigName

echo "Sleeping 3 minutes to allow time for cleanup to complete"
sleep 180
echo "End of cleanup script"
