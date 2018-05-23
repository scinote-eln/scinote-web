# Ignoring so Heroku builds pass
#TARGET_ROOT = "#{Dir.pwd}/app/javascript/src/componentLoader".freeze
#COMPONENTS_ROOT = "#{TARGET_ROOT}/components".freeze
#UBER_CONFIG_PATH = "#{TARGET_ROOT}/availableAddons.js".freeze
#
#begin
## clear previous build
#FileUtils.rm_f Dir.glob("#{COMPONENTS_ROOT}/*")
#FileUtils.rm_f Dir.glob(UBER_CONFIG_PATH)
#File.new(UBER_CONFIG_PATH, 'w+')
#enabled_addons = []
#
#Dir.foreach('addons/') do |path|
#  addons_client_root = "addons/#{path}/client"
#  next unless Dir.exist? addons_client_root
#  File.open(UBER_CONFIG_PATH, 'w') do |file|
#    file.puts("import #{path} from \'./components/#{path}/config.js\';")
#  end
#  enabled_addons << "#{path}"
#  File.symlink("#{Dir.pwd}/#{addons_client_root}", "#{COMPONENTS_ROOT}/#{path}")
#end
#
#File.open(UBER_CONFIG_PATH, 'a') do |file|
#  file.puts("export default { #{enabled_addons.join(", ").gsub(/\"/, '')} };")
#end
#
## handles error on the platforms that does not support symlink
## http://ruby-doc.org/core-2.2.0/File.html#symlink-method
#rescue
#  puts '[SciNote] Unable to load React components from addons!'
#  puts '[SciNote] Your system does not support symlink!'
#end
