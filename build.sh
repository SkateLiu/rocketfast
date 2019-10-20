#!/bin/bash
echo $PATH
git fetch
git checkout master
git pull origin master
ruby config_inhouse.rb
cd Rocket
bundle install
#拉取pod 库
pod install --repo-update
fastlane inhouse
#./autotest.sh