#!/bin/bash
echo $PATH
git fetch
echo $branch
git checkout $branch
git pull origin $branch
ruby config_inhouse.rb
cd Rocket
bundle install
#拉取pod 库
pod install --repo-update
fastlane inhouse
#./autotest.sh