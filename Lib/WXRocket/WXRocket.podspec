Pod::Spec.new do |s|
  s.name         = "WXRocket"
  s.version      = "0.1.1"
  s.summary      = "Profiling/Debugging assist tools for iOS."

  s.description  = <<-DESC
  WXRocket is profiling/debugging assist tools for iOS. It's designed to help iOS developers improve development productivity and assist in optimizing the App performance.
                   DESC

  s.homepage     = "https://github.com"
  s.license      = {
    :type => 'Copyright',
    :text => <<-LICENSE
      © 2008-present, Meitu, Inc. All rights reserved.
    LICENSE
  }

  s.author       = { "XX" => "XX" }

  s.platform     = :ios, "8.0"

  s.source       = { :git => "https://github.com/teemo/WXRocket.git", :tag => "#{s.version}" }

  s.default_subspec = 'DefaultAll'

  s.subspec 'DefaultAll' do |sp|
    sp.source_files  = 'WXRocket/DefaultPlugins/**/*.{h,m,mm}'
    sp.dependency 'WXRocket/Core'
    sp.dependency 'WXRocket/EnergyPlugins/CPUTrace'
  end

  # ――― Basic ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.subspec 'Core' do |sp|
    sp.public_header_files = 'WXRocket/Core/**/*.{h}'
    sp.source_files = 'WXRocket/Core/**/*.{h,m}'
    sp.dependency 'WXRocket/Utils'
  end


  s.subspec 'Utils' do |sp|
      sp.public_header_files = 'WXRocket/Utils/*.{h}'
      sp.source_files = 'WXRocket/Utils/**/*.{h,m,mm}'
      sp.dependency 'MTAppenderFile'
      sp.framework = 'Foundation', 'SystemConfiguration'

      cpp_files = 'WXRocket/Utils/*.{cpp,hpp}'
      sp.exclude_files = cpp_files
      sp.subspec 'cpp' do |cpp|
   
        cpp.source_files = cpp_files
        cpp.libraries = "stdc++"
      end
  end

  s.subspec 'StackBacktrace' do |sp|
      sp.public_header_files =
        'WXRocket/StackBacktrace/WXRocketStackFrameSymbolicsRemote.h',
        'WXRocket/StackBacktrace/wxr_stack_backtrace.h'

      sp.source_files = 'WXRocket/StackBacktrace/**/*.{h,m,mm,cpp}'
      sp.dependency 'WXRocket/Utils'
      sp.framework = 'Foundation'
  end

  # ――― Energy ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.subspec 'EnergyPlugins' do |ep|
    # CPU Trace
    ep.subspec 'CPUTrace' do |cpu|
        cpu.source_files = 'WXRocket/EnergyPlugins/CPUTrace/**/*.{h,m,mm}'
        cpu.dependency 'WXRocket/Core'
        cpu.dependency 'WXRocket/StackBacktrace'
        cpu.libraries = "stdc++"
    end
  end # EnergyPlugins


  s.requires_arc = true

end
