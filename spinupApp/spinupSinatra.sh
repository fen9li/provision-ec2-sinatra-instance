#!/bin/bash
# Install ruby environment software, run as ec2-user

# install rvm
cd /home/ec2-user
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
curl -sSL https://get.rvm.io | bash -s stable
source /home/ec2-user/.rvm/scripts/rvm

# install ruby
rvm install 2.4.1
rvm --default use 2.4.1 

# install gem
wget https://rubygems.org/rubygems/rubygems-2.6.13.tgz
tar xzf rubygems-2.6.13.tgz
cd rubygems-2.6.13
ruby setup.rb

# install sinatra
gem install bundle --no-document
gem install sinatra --no-document

# start sinatra helloworld web service
cd /tmp/spinupApp/simple-sinatra-app/
nohup ruby helloworld.rb > /dev/null 2>&1 & 
