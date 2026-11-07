require 'xcodeproj'

project_path = 'ios/App/App.xcodeproj'
project = Xcodeproj::Project.open(project_path)
app = project.targets.find { |target| target.name == 'App' }
raise 'Capacitor App target not found' unless app

unless project.targets.any? { |target| target.name == 'LyamfiWidgets' }
  widgets = project.new_target(:app_extension, 'LyamfiWidgets', :ios, '16.0')
  group = project.main_group.new_group('LyamfiWidgets', 'App/LyamfiWidgets')
  swift = group.new_file(File.expand_path('ios/App/LyamfiWidgets/LyamfiWidgets.swift'))
  widgets.add_file_references([swift])

  widgets.build_configurations.each do |config|
    config.build_settings.merge!({
      'PRODUCT_BUNDLE_IDENTIFIER' => 'com.lyamfi.app.LyamfiWidgets',
      'INFOPLIST_FILE' => 'App/LyamfiWidgets/Info.plist',
      'CODE_SIGN_STYLE' => 'Automatic',
      'SWIFT_VERSION' => '5.0',
      'TARGETED_DEVICE_FAMILY' => '1,2',
      'SKIP_INSTALL' => 'YES',
      'LD_RUNPATH_SEARCH_PATHS' => '$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks',
      'GENERATE_INFOPLIST_FILE' => 'NO',
    })
  end

  app.add_dependency(widgets)
  embed = app.copy_files_build_phases.find { |phase| phase.name == 'Embed App Extensions' }
  embed ||= app.new_copy_files_build_phase('Embed App Extensions')
  embed.dst_subfolder_spec = '13'
  embed.add_file_reference(widgets.product_reference)

  app.build_configurations.each do |config|
    config.build_settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'YES'
    config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'App/App/App.entitlements'
    config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
  end
  project.save
end
puts 'LyamfiWidgets target installed and embedded in App.'
