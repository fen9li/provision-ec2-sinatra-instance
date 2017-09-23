# Provision AWS EC2 instance to Test Ruby Code on GitHub Continuously 

Continuous Integration (CI) is a development practice that requires developers to integrate code into a shared repository several times a day. Each check-in is then verified by an automated build, allowing teams to detect problems early. This project implements a solution to let developers / system engineers test ruby base web code on Github easily.

  - AWS based 
  - Github based
  - Ruby code testing ready

# How it works

  - Developers have a new version ruby code pushed to Github for testing
  - Developer / system engineers run spinup.sh script from an aws management host
  - Testing result is ready for reviewing after 30 minutes

# AWS resources / services consumed / used in this solution
> All required aws resoureces are self contained, automatically created and can be easily cleaned up.
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
> Setup a linux host as management host (or can be called build server), which is aws cli and Github ready. The linux host can be an on-premise one or an aws ec2 instance; Can be a physical one or virtual.
* Issue 'aws --version' command and should see similar like below: 

```sh
[username@hostname ~]$ aws --version
aws-cli/1.11.151 Python/2.7.5 Linux/3.10.0-514.26.2.el7.x86_64 botocore/1.7.9
[username@hostname ~]$
```

* Ensure configure it as per your own access credentials: 
```sh
[username@hostname ~]$ cat .aws/config
[default]
output = json
region = ap-southeast-2
[username@hostname ~]$ cat .aws/credentials
[default]
aws_access_key_id = XXXXXXXXXXXXXXXXXXXX
aws_secret_access_key = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
[username@hostname ~]$
```

* Install git on this linux management host if not yet and test if you can clone a repo from Github:
 
```sh
[username@hostname ~]$ git --version
git version 1.8.3.1
[username@hostname ~]$ git clone https://github.com/fen9li/simple-sinatra-app
Cloning into 'simple-sinatra-app'...
remote: Counting objects: 8, done.
remote: Compressing objects: 100% (6/6), done.
remote: Total 8 (delta 1), reused 8 (delta 1), pack-reused 0
Unpacking objects: 100% (8/8), done.
[username@hostname ~]$
```

### Set up
* git clone below repo from develop branch (I am not ready to merge into master branch at the time of writing this README). 

```sh
[username@hostname test]$ git clone -b develop https://github.com/fen9li/provision-ec2-sinatra-instance
Cloning into 'provision-ec2-sinatra-instance'...
remote: Counting objects: 116, done.
remote: Compressing objects: 100% (91/91), done.
remote: Total 116 (delta 65), reused 58 (delta 23), pack-reused 0
Receiving objects: 100% (116/116), 21.08 KiB | 0 bytes/s, done.
Resolving deltas: 100% (65/65), done.
[username@hostname test]$ cd provision-ec2-sinatra-instance/
[username@hostname provision-ec2-sinatra-instance]$ pwd
/home/username/test/provision-ec2-sinatra-instance
[username@hostname provision-ec2-sinatra-instance]$
```

> Make a note on 'pwd' command output. It is the basedir in spinup.conf. 

* Expected files and directories structure when change directory to base directory: 

```sh
[username@hostname provision-ec2-sinatra-instance]$ tree
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
[username@hostname provision-ec2-sinatra-instance]$
```

* Configure spinup.conf 
> Please be very careful with those one time off settings, such as s3 bucket name and aws region. It is recommended to do it only at this set up stage. Once set, dont change it.  
* run ./createRolesAndBucket.sh to create one s3 bucket and two IAM roles. Double check from aws management console to ensure.

### Run ./spinup.sh script 

```sh
[username@hostname provision-ec2-sinatra-instance]$ ./spinup.sh
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
[username@hostname provision-ec2-sinatra-instance]$
```

> It takes 30 minutes to get the result. 

### Daily operation tasks 
* To lock down new provisioned instances, just destroy the private key of the keypair. Once you are happy with everything and no need to logon any new instances, destroy the private key. This will give new instances hightest security.
* To test new version ruby code in same Github repo and branch, move to base directory and run ./spinup.sh script directly.
* To test new version ruby code in different Github repo and branch, configure 'webAppRepo' & 'webAppRepo' in spinup.conf accordingly and then run ./spinup.sh script.

```sh
[username@hostname provision-ec2-sinatra-instance]$ grep webAppRepo spinup.conf
webAppRepo="https://github.com/fen9li/simple-sinatra-app"
webAppRepoBranch="develop"
[username@hostname provision-ec2-sinatra-instance]$
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
