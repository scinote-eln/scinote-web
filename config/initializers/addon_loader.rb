# This code fetch the components from the addons but only in the root of the
# addon/**/client folder.

TARGET_ROOT = "#{Dir.pwd}/app/javascript/src/react-hijack/addons".freeze

begin
# clear previous build
FileUtils.rm_f Dir.glob("#{TARGET_ROOT}/*")

Dir.foreach('addons/') do |path|
  addons_client_root = "addons/#{path}/client"
  next unless Dir.exist? addons_client_root
  all_files = Dir.glob("#{addons_client_root}/*\.*")
  all_files.each do |component|
    new_path = component.gsub("#{addons_client_root}/", '')
    File.symlink("#{Dir.pwd}/#{component}", "#{TARGET_ROOT}/#{new_path}")
  end
end
# handles error on the platforms that does not support symlink
# http://ruby-doc.org/core-2.2.0/File.html#symlink-method
rescue NotImplemented => error
  puts '[sciNote] Unable to load React components from addons!'
  puts '[sciNote] Your system does not support symlink!'
  puts "[sciNote] #{error.message}"
end
