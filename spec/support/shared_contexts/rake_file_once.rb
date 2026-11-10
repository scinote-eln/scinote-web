# frozen_string_literal: true

require 'rake'

# Loads lib/tasks/<file>.rake ONCE per process into its own Rake::Application and re-enables the tasks for every
# example. Re-loading a file on every example resets its line coverage, so use this context for rake files whose
# namespace differs from the file name or that define several namespaces.
#
#   include_context 'rake file loaded once', 'rename_duplicates_protocols'
#   rake_task('protocols:rename_duplicates_team_protocols').invoke
module RakeFileOnce
  APPLICATIONS = {}

  def self.application_for(file)
    APPLICATIONS[file] ||= begin
      app = Rake::Application.new
      original = Rake.application
      Rake.application = app
      Rake::Task.define_task(:environment)
      load Rails.root.join("lib/tasks/#{file}.rake").to_s
      app
    ensure
      Rake.application = original
    end
  end
end

shared_context 'rake file loaded once' do |file|
  around do |example|
    original = Rake.application
    app = RakeFileOnce.application_for(file)
    app.tasks.each(&:reenable)
    Rake.application = app
    example.run
  ensure
    Rake.application = original
  end

  def rake_task(name)
    Rake.application[name]
  end
end
