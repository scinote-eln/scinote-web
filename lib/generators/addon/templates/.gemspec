$:.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require '${FOLDERS_PATH}/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = '${FULL_UNDERSCORE_NAME}'
  s.version     = ${NAME}::VERSION
  s.authors     = ['']
  s.email       = ['']
  s.homepage    = ''
  s.summary     = ''
  s.description = ''
  s.license     = ''

  s.files = Dir['{app,config,db,lib}/**/*',
                'LICENSE.txt',
                'Rakefile',
                'README.rdoc']
  s.test_files = Dir['test/**/*']

  s.add_dependency 'rails', '~> 4.2.5'
  s.add_dependency 'deface', '~> 1.0'
end
