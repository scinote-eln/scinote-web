TARGET_ROOT = "#{Dir.pwd}/app/javascript/src/componentLoader/components".freeze

begin
# clear previous build
FileUtils.rm_f Dir.glob("#{TARGET_ROOT}/*")

available_addons = []
Dir.foreach('addons/') do |path|
  addons_client_root = "addons/#{path}/client"
  next unless Dir.exist? addons_client_root
  available_addons << path
  File.symlink("#{Dir.pwd}/#{addons_client_root}", "#{TARGET_ROOT}/#{path}")
end

# generate a file with available addons
if available_addons.any?
  file_name = "#{Dir.pwd}/app/javascript/src/componentLoader/availableAddons.js"
  # remove if already exists
  FileUtils.rm_f Dir.glob(file_name)
  File.new(file_name, 'w+')
  File.open(file_name, 'w') do |file|
    file.write("export default #{available_addons};")
  end
end

# handles error on the platforms that does not support symlink
# http://ruby-doc.org/core-2.2.0/File.html#symlink-method
rescue
  puts '[sciNote] Unable to load React components from addons!'
  puts '[sciNote] Your system does not support symlink!'
end
