require 'singleton'

class AddonsSpecLoader
  include Singleton
  include AddonsHelper

  # rspec will recognise symlinks in the second run
  def mount
    FileUtils.rm_f Dir.glob("#{Dir.pwd}/spec/addons/*")
    available_addons.each do |addon|
      specs_path = "addons/#{addon}/spec"
      next unless Dir.exist? specs_path
      File.symlink("#{Dir.pwd}/#{specs_path}",
                   "#{Dir.pwd}/spec/addons/#{addon}")
    end
  end

  # cucumber cannot resolve path with symlinks so we copy files from addons
  def copy_to_features
    FileUtils.rm_f Dir.glob("#{Dir.pwd}/features/addons/*")
    available_addons.each do |addon|
      feature_path = "addons/#{addon}/features"
      next unless Dir.exist? feature_path
      FileUtils.copy_entry("#{Dir.pwd}/#{feature_path}",
                           "#{Dir.pwd}/features/addons/#{addon}")
    end
  end

  private

  def available_addons
    list_all_addons.map { |addon| addon.to_s.split('::').last.underscore }
  end
end

if ENV['RAILS_ENV'].in? %w(test development)
  begin
    puts '[SciNote] Generating symlinks for addons!'
    puts '[SciNote] Copying features from addons!'
    AddonsSpecLoader.instance.mount
    AddonsSpecLoader.instance.copy_to_features
  rescue
    puts '[SciNote] Unable to load specs from addons!'
    puts '[SciNote] Your system does not support symlink!'
  end
end
