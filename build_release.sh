#!/bin/bash
echo $PATH
git fetch
git pull origin master
git checkout master
cd Rocket
bundle install
#拉取pod 库
pod install --repo-update
fastlane beta
fastlane deliver --ipa "RocketFast.ipa" --force
#./autotest.sh