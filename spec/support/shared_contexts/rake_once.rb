# frozen_string_literal: true

require 'rake'

# Like the 'rake' context, but loads the rake file only once per process (the task is re-enabled before each example).
# Ruby resets the line coverage of a file every time it is loaded, so reloading per example would keep only the
# counters of the last example. Also works for rake files that are not named after the task namespace: override
# `task_path` (e.g. 'lib/tasks/db_users').
shared_context 'rake once' do
  RAKE_ONCE_APPLICATIONS = {} unless defined?(RAKE_ONCE_APPLICATIONS)

  let(:task_name) { self.class.top_level_description }
  let(:task_path) { "lib/tasks/#{task_name.split(':').first}" }
  let(:rake) do
    RAKE_ONCE_APPLICATIONS[task_path] ||= Rake::Application.new.tap do |app|
      previous = Rake.application
      begin
        Rake.application = app
        Rake::Task.define_task(:environment)
        app.rake_require(task_path, [Rails.root.to_s], [])
      ensure
        Rake.application = previous
      end
    end
  end
  subject { rake[task_name] }

  around do |example|
    previous = Rake.application
    Rake.application = rake
    example.run
  ensure
    Rake.application = previous
  end

  before { rake.tasks.each(&:reenable) }
end
