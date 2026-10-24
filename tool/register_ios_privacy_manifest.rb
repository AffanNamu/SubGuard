# Adds ios/Runner/PrivacyInfo.xcprivacy to the Runner target's "Copy Bundle
# Resources" phase. Apple only honours the manifest if it is inside the app
# bundle. Safe to run more than once. Needs:  gem install xcodeproj
require 'xcodeproj'

project = Xcodeproj::Project.open('ios/Runner.xcodeproj')
target = project.targets.find { |t| t.name == 'Runner' } or abort 'Runner target not found'
group = project.main_group.find_subpath('Runner', true)

ref = group.children.find { |c| c.respond_to?(:path) && c.path == 'PrivacyInfo.xcprivacy' } ||
      group.new_reference('PrivacyInfo.xcprivacy')
# add_file_references would route an unknown type like .xcprivacy to Compile
# Sources, so name the resources phase explicitly.
unless target.resources_build_phase.files.any? { |f| f.file_ref == ref }
  target.resources_build_phase.add_file_reference(ref)
end

project.save
puts 'PrivacyInfo.xcprivacy is in the Runner target resources'
