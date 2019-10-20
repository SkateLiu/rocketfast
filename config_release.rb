require 'xcodeproj'

project_path = './Rocket/RocketDemo.xcodeproj'    # 工程的全路径
project = Xcodeproj::Project.open(project_path)

puts 'ruby开始修改证书id和描述文件...'

project.targets.each do |target|
    target.build_configurations.each do |config|

        if config.name == 'Release'
            config.build_settings["PROVISIONING_PROFILE_SPECIFIER"] = "5b35c1eb-e9e5-4eac-a517-96d4f730e84a"
        end

    end
end

project.save
puts '修改完成...'
