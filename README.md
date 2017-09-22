# Provision AWS EC2 instance to Test Gitgub Repo Continuously 

Continuous Integration (CI) is a development practice that requires developers to integrate code into a shared repository several times a day. Each check-in is then verified by an automated build, allowing teams to detect problems early. This project implements a solution to let developers / system engineers test ruby base web code on Github easily.

  - AWS based 
  - Github based
  - Ruby code testing ready

# How it works

  - Developers have a new version ruby code pushed to Github for testing
  - Developer / system engineers run spinup.sh script from an aws management host
  - Testing result is ready for reviewing after 30 minutes

# AWS resources / services consumed / used in this solution

  - A t2.micro ec2 Linux instance (freetier eligible)
  - A s3 bucket (capacity consumed depends on the ruby code size for testing)
  - cloudformation service
  - codedeploy service
  - vpc,subnet,security group,internet gateway,routing table etc
  - Amazon standard Linux image (free of charge)
  - keypair (only public key of the keypair is required unless you want to ssh to new instance)

# Github resources

  - A Github account
  - A Github repository for developers to share ruby code for testing

# Usage
### Prepare
> Setup a linux host as management host (or can be called build server), which is aws cli and Github ready 
* The linux host can be an on-premise one or an aws ec2 instance; Can be a physical one or virtual.
* Issue 'aws --version' command and should see similar like below: 

```sh
 ~]$ aws --version
aws-cli/1.11.151 Python/2.7.5 Linux/3.10.0-514.26.2.el7.x86_64 botocore/1.7.9
 ~]$
```

* Ensure configure it as per your own access credentials: 
```sh
 ~]$ cat .aws/config
[default]
output = json
region = ap-southeast-2
 ~]$ cat .aws/credentials
[default]
aws_access_key_id = XXXXXXXXXXXXXXXXXXXX
aws_secret_access_key = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
 ~]$
```

* Install git on this linux management host if not yet and test if you can clone a repo from Github:
 
```sh
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

### First time run
* git clone below repo from develop branch (I am not ready to merge into master branch at the time of writing this README). 

```sh
~]$ git clone -b develop https://github.com/fen9li/provision-ec2-sinatra-instance
Cloning into 'provision-ec2-sinatra-instance'...
remote: Counting objects: 60, done.
remote: Compressing objects: 100% (44/44), done.
remote: Total 60 (delta 28), reused 43 (delta 14), pack-reused 0
Unpacking objects: 100% (60/60), done.
~]$
```

* Expected files and directories after git clone should be as below: 

```sh
~]$ tree
.
└── provision-ec2-sinatra-instance
    ├── cfTemplate.json
    ├── cleanupSpinup.sh
    ├── CodeDeployServiceRole-Trust.json
    ├── countdownTimer.sh
    ├── createRolesAndBucket.sh
    ├── deleteRolesAndBucket.sh
    ├── fliSinatra-EC2-S3-Permissions.json
    ├── fliSinatra-EC2-Trust.json
    ├── rolesAndBucket.conf
    ├── spinupApp
    │   ├── afterInstall.sh
    │   ├── appspec.yml
    │   ├── preInstall.sh
    │   ├── spinupSinatra.sh
    │   └── startSpinupApp.sh
    ├── spinup.conf
    ├── spinup.sh
    └── updateAppArchive.sh

2 directories, 17 files
~]$
```

* Move to base directory (suppose you start git clone from your home directory)

```sh
]$ cd provision-ec2-sinatra-instance/
 provision-ec2-sinatra-instance]$ pwd
/home/<your user account name>/provision-ec2-sinatra-instance
 provision-ec2-sinatra-instance]$
```

* Configure rolesAndBucket.conf and run ./createRolesAndBucket.sh to create aws s3 bucket and 2 IAM roles. Double check from aws management console to ensure.
* Configure Github repo and branch where ruby code have been pushed. Configure base directory, cloudformation stack name and parameters and codedeploy related names as per invidual favour in spinup.conf. 
* Run ./spinup.sh script now and you go ...

```sh
 provision-ec2-sinatra-instance]$ ./spinup.sh
Fri Sep 22 23:26:11 AEST 2017
Starting cleanup of possible legacy resources
...
############################

A new sinatra web server has been spinned up upon an AWS ec2 instance. To test it, enter below link in your web browser... and you should see a Hello World message ...

http://54.252.251.160/

############################

Also you can double check from your aws management console, you should be able to see an ec2 instance with below details...
Instance Id: i-xxxxxxxxxxxxxxxxx
TagKey name: UUID
TageKey value: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

Fri Sep 22 23:56:36 AEST 2017
############################
 provision-ec2-sinatra-instance]$
```

* It takes 30 minutes to get the result. 
* Logon this new instance and check up directory "/opt/codedeploy-agent/deployment-root/<deploymentGroupId>/<deploymentId>" and have fun.

### Daily operation tasks 
* To lock down new provisioned instances, just destroy the private key of the keypair. Once you are happy with everything and no need to logon any new instances, destroy the private key. This will give new instances hightest security.
* To test new version ruby code in same Github repo and branch, move to base directory and run ./spinup.sh script directly.
* To test new version ruby code in different Github repo and branch, configure 'webAppRepo' & 'webAppRepo' in spinup.conf accordingly and then run ./spinup.sh script.

```sh
 provision-ec2-sinatra-instance]$ grep webAppRepo spinup.conf
webAppRepo="https://github.com/fen9li/simple-sinatra-app"
webAppRepoBranch="develop"
 provision-ec2-sinatra-instance]$
```

* To cleanup aws resources when finish ruby code testing, run ./cleanupSpinup.sh.
* To cleanup s3 bucket and IAM roles created for this solution, run ./deleteRolesAndBucket.sh script.

# Where to go next
* This CI solution is designed for ruby sinatra based web app code testing at the time of writing. However, with extra time and effort, it can be tailored to test any source code, such as php etc.  
* The solution can be easily intergrated with Puppet, which makes it a powerful solution to support large scale environment.
* This solution can provision an ec2 instance to test ruby sinatra based web app code in around 30 minutes. It is recommended to create a private AMI to speed up the provisioning process, should the code needs to test several times a day.
* It is recommended to do further automation based on this soultion, which aims new version source code pushing to Github would trigger the testing procedure automatically. 
* Every time spinup.sh script runs, aws allocates a public IP address from its public IP address pool. So the new instance public IP address is not a fix IP address. This wont be a problem in real life. But if a fix IP address is required, an EIP resource can be added. 

License
----
MIT
