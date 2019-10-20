#!/bin/bash
echo $PATH
git fetch
git checkout master
git pull origin master
cd Rocket
bundle install
#拉取pod 库
pod install --repo-update
ruby config_release.rb
fastlane release
fastlane deliver --ipa "RocketFast.ipa" --force
#./autotest.sh