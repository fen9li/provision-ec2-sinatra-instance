#!/bin/bash
# updateAppArchive.sh - once developers updated web source code,
# it would be necessary to update App archive for new deployment.

# Usage: cd to the directory containing this script and
#        give the command "./updateAppArchive.sh"

source spinup.conf
source rolesAndBucket.conf

# get web app repo name
webAppRepoName="$(cut -d'/' -f5 <<<"$webAppRepo")"

# update spinupAPP zip archive locally
echo "Updating spinupApp.zip locally"

# delete legacy spinupApp.zip if exists
[ -e spinupApp.zip ] && rm spinupApp.zip

# delete legacy web app source code directory if exists
cd spinupApp
[ -e "$webAppRepoName" ] && rm -Rf "$webAppRepoName"

# git clone current version web app source code
git clone -b "$webAppRepoBranch" "$webAppRepo"

# trim .git directory in new local clone
cd "$webAppRepoName"
rm -Rf .git

# zip new version spinupApp zip archive
cd ..
zip -qr ../spinupApp.zip *
cd ..

# Delete possible legacy archive and upload current version to S3
echo "Updating spinupApp.zip in s3 bucket"
aws s3 rm "s3://$s3BucketName/spinupApp.zip"
aws s3 cp spinupApp.zip "s3://$s3BucketName"

exit 0
