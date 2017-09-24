# Provision AWS EC2 instance to Test a Simple Sinatra App on GitHub Continuously

Continuous Integration (CI) is a development practice that requires developers to integrate code into a shared repository several times a day. Each check-in is then verified by an automated build, allowing teams to detect problems early. This project implements a solution to let developers / system engineers test ruby base web code on Github easily.

  - AWS based
  - Github based
  - Ruby code testing ready

# How it works

  - Developers have a new version ruby code pushed to Github for testing
  - Developer / system engineers run spinup.sh script from an aws management host
  - Testing result is ready for reviewing after 30 minutes

# AWS resources / services consumed / used in this solution
> AWS Freetier user eligible. 
> All required aws resoureces are self contained, automatically created and can be easily cleaned up.
  - A ec2 Linux instance - t2.micro (freetier eligible)
  - A s3 bucket - capacity consumed depends on the ruby code size for testing (5GiB for freetier user)
  - cloudformation service (free of charge)
  - codedeploy service (free of charge)
  - 2 keypairs (one for ssh, one for lockdown)(free of charge)
  - vpc,subnet,security group,internet gateway,routing table etc (free of charge)
  - Amazon standard Linux image 'ami-30041c53' (free of charge)

# Github resources

  - A Github account 
  - A Github repository for developers to share ruby code for testing

# Usage
### Prepare
> Setup a linux host as management host (or can be called build server), which is both aws cli and Github ready. 
> The linux host can be an on-premise one or an aws ec2 instance; Can be a physical one or virtual.
> Configure ssh keypair and lockdown keypair.

* Install git,zip,unzip,curl,wget,tree. Install and configure aws cli.

```sh
~]# yum -y update
... ...
~]# uname -a
Linux sinatra.fen9.li 3.10.0-514.26.2.el7.x86_64 #1 SMP Tue Jul 4 15:04:05 UTC 2017 x86_64 x86_64 x86_64 GNU/Linux
~]# cat /etc/os-release
NAME="CentOS Linux"
VERSION="7 (Core)"
ID="centos"
ID_LIKE="rhel fedora"
VERSION_ID="7"
PRETTY_NAME="CentOS Linux 7 (Core)"
ANSI_COLOR="0;31"
CPE_NAME="cpe:/o:centos:centos:7"
HOME_URL="https://www.centos.org/"
BUG_REPORT_URL="https://bugs.centos.org/"

CENTOS_MANTISBT_PROJECT="CentOS-7"
CENTOS_MANTISBT_PROJECT_VERSION="7"
REDHAT_SUPPORT_PRODUCT="centos"
REDHAT_SUPPORT_PRODUCT_VERSION="7"

~]# yum -y install git zip unzip wget tree curl
... ...
~]$ aws --version
aws-cli/1.11.151 Python/2.7.5 Linux/3.10.0-514.26.2.el7.x86_64 botocore/1.7.9
~]$
~]$ cat .aws/config
[default]
output = json
region = ap-southeast-2
[username@hostname ~]$ cat .aws/credentials
[default]
aws_access_key_id = XXXXXXXXXXXXXXXXXXXX
aws_secret_access_key = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
~]$

~]$ git --version
git version 1.8.3.1
~]$ git clone https://github.com/fen9li/simple-sinatra-app
Cloning into 'simple-sinatra-app'...
remote: Counting objects: 8, done.
remote: Compressing objects: 100% (6/6), done.
remote: Total 8 (delta 1), reused 8 (delta 1), pack-reused 0
Unpacking objects: 100% (8/8), done.
~]$
```

* Create 2 keypairs - sinatra-ssh-keypair & sinatra-lockdown-keypair. Import both public keys to aws. Keep private key file of sinatra-ssh-keypair in safe place. Destroy private key file of sinatra-lockdown-keypair.

```sh
~]$ aws ec2 describe-key-pairs --filters "Name=key-name,Values=sinatra-lockdown-keypair-public,sinatra-ssh-keypair-public"
{
    "KeyPairs": [
        {
            "KeyName": "sinatra-lockdown-keypair-public",
            "KeyFingerprint": "3c:d2:27:0d:6d:09:de:54:91:93:72:44:5e:d7:31:df"
        },
        {
            "KeyName": "sinatra-ssh-keypair-public",
            "KeyFingerprint": "73:4d:41:5c:88:16:fe:2e:e0:1f:d0:75:a4:e8:c6:69"
        }
    ]
}
~]$
```

### Set up
* Clone repo 'https://github.com/fen9li/provision-ec2-sinatra-instance' upon develop branch.

```sh
~]$ git clone -b develop https://github.com/fen9li/provision-ec2-sinatra-instance
Cloning into 'provision-ec2-sinatra-instance'...
… …
Resolving deltas: 100% (65/65), done.
~]$ cd provision-ec2-sinatra-instance/
provision-ec2-sinatra-instance]$ pwd
…/…/provision-ec2-sinatra-instance
provision-ec2-sinatra-instance]$
```

> Make a note on 'pwd' command output. This is the base directory must be configured correctly in spinup.conf.

* Expected files and directories structure when change directory to base directory:

```sh
provision-ec2-sinatra-instance]$ tree
.
├── cfTemplate.json
├── cleanupSpinup.sh
├── CodeDeployServiceRole-Trust.json
├── countdownTimer.sh
├── createRolesAndBucket.sh
├── deleteRolesAndBucket.sh
├── fliSinatra-EC2-S3-Permissions.json.base
├── fliSinatra-EC2-Trust.json
├── README.md
├── spinupApp
│   ├── afterInstall.sh
│   ├── appspec.yml
│   ├── preInstall.sh
│   ├── spinupSinatra.sh
│   └── startSpinupApp.sh
├── spinup.conf
├── spinup.sh
└── updateAppArchive.sh

1 directory, 17 files
provision-ec2-sinatra-instance]$
```

* Configure spinup.conf
1. basedir – the base directory. Must be configured correctly. Wont change in daily operation.
2. webAppRepo & webAppRepoBranch – Github repo and branch where the testing code is kept.
3. SSHLocation – the IP address from which ssh is allowed to new instance.
4. imageId – the AMI used to lauch new instance. Must set to Amazon base linux image (ami-30041c53) in this solution code context.
5. KeyName – default set to sinatra-lockdown-keypair-public to lockdown new instance. Set to sinatra-ssh-keypair-public to allow logon to new instance, for example debugging is required.  
6. s3BucketName – the s3 bucket used as placeholder for testing code archive. Once set, dont change it.
7. region – the aws region from which run this solution. Once set, don’t change it.
8. codeDeployServiceRoleName & instanceProfileName – two roles required in this solution. Once set, dont change it.
9. Other settings – as per invidual favour.

An example:

```sh
 provision-ec2-sinatra-instance]$ egrep -v -e '^#' -e '^$' spinup.conf
webAppRepo="https://github.com/fen9li/simple-sinatra-app"
webAppRepoBranch="develop"
basedir="/home/fli/provision-ec2-sinatra-instance"
cfStackName="provisionSinatraWebService"
SSHLocation="0.0.0.0/0"
imageId="ami-30041c53"
keyName="sinatra-lockdown-keypair-public"
cdAppName="spinupSinatraServer"
cdDeployGroupName="spinupSinatraServerDG"
cdDeploymentConfigName="spinupSinatraServerDefault"
cdDeploymentDescription="Spin up Sinatra Server Deployment"
s3BucketName="fli-sinatra"
region="ap-southeast-2"
codeDeployServiceRoleName="CodeDeployServiceRole"
instanceProfileName="fliSinatra-EC2-Instance-Profile"
 provision-ec2-sinatra-instance]$
```

* run ./createRolesAndBucket.sh to create required s3 bucket and IAM roles. Double check from aws management console to ensure.

```sh
 provision-ec2-sinatra-instance]$ ./createRolesAndBucket.sh
Creating s3 bucket
{
    "Location": "http://fli-sinatra.s3.amazonaws.com/"
}
... ...
 provision-ec2-sinatra-instance]$
```

### Run ./spinup.sh script

```sh
provision-ec2-sinatra-instance]$ ./spinup.sh
Fri Sep 22 13:26:11 AEST 2017
Starting cleanup of possible legacy resources
...
############################

A new sinatra web server has been spinned up upon an AWS ec2 instance. To test it, enter below link in your web browser... and you should see a Hello World message ...

http://54.252.251.160/

############################

Also you can double check from your aws management console, you should be able to see an ec2 instance with below details...
Instance Id: i-xxxxxxxxxxxxxxxxx
TagKey name: UUID
TagKey value: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

Fri Sep 22 13:56:36 AEST 2017
############################
provision-ec2-sinatra-instance]$
```

> It takes 30 minutes to get the result. 5 minutes for cleaning up possible legacy resources. 5 minutes for launching new instance. 20 minutes for getting ready web service on new instance.

### Daily operation tasks
> Lock down new instance by using sinatra-lockdown-keypair. 

* To test new version code in Github repo, configure 'webAppRepo' & 'webAppRepoBranch' in spinup.conf accordingly and then run ./spinup.sh script.

* To logon new instance for debugging, configure keyName="sinatra-ssh-keypair-public" in spinup.conf and then run ./spinup.sh script.

* To stop code testing and clean up provisioned aws resources, run ./cleanupSpinup.sh script.

* To cleanup s3 bucket and IAM roles, run ./cleanupSpinup.sh script first to clean up aws resources, then run ./deleteRolesAndBucket.sh script to delete s3 bucket and IAM roles.

# Where to go next
* This CI solution is tailored for ruby sinatra based web app code testing. It can be modified to test any other source codes, such as php etc.
* This solution can be easily intergrated with Puppet, which makes it a powerful solution to support large scale environment.
* This solution can provision an ec2 instance to test ruby sinatra based web app code in around 30 minutes. It is recommended to create a private AMI to speed up the provisioning process, should code testing is required several times a day.
* It is recommended to do further automation, which aims new version source code pushing to Github would trigger the testing procedure automatically.
* Every time spinup.sh script runs, aws allocates a public IP address from its public IP address pool. Thus, new instance public IP address is not a fix one. This wont be a problem in real life. If a fix IP address is required, an EIP can be added.

License
----
MIT
