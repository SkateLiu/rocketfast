#!/bin/bash
echo $PATH
git pull
git checkout master
cd Rocket
bundle install
#拉取pod 库
pod install --repo-update
fastlane beta
#./autotest.sh