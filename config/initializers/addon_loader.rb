# This code fetch the components from the addons but only in the root of the
# addon/**/client folder.

TARGET_ROOT = "#{Dir.pwd}/app/javascript/src/componentLoader/components".freeze

begin
# clear previous build
FileUtils.rm_f Dir.glob("#{TARGET_ROOT}/*")

Dir.foreach('addons/') do |path|
  addons_client_root = "addons/#{path}/client"
  next unless Dir.exist? addons_client_root
  File.symlink("#{Dir.pwd}/#{addons_client_root}", "#{TARGET_ROOT}/#{path}")
end
# handles error on the platforms that does not support symlink
# http://ruby-doc.org/core-2.2.0/File.html#symlink-method
rescue
  puts '[sciNote] Unable to load React components from addons!'
  puts '[sciNote] Your system does not support symlink!'
end
