# frozen_string_literal: true

# Some code paths and specs change process-wide state and never put it back, which makes later examples in
# the same process fail depending on the order the files run in. Put the state back after every example:
#
# * TeamImporter#import_from_dir (reached through data:team_import, TemplatesService, the importer specs, ...)
#   removes some MyModule/Activity callbacks and re-adds them at the END of the callback chain when it
#   succeeds (and not at all when it fails). That changes the callback order for everything that runs later
#   (activities without a user target, notification recipients that crash, 400s from the API).
# * ActiveJob::Base.queue_adapter = :test (several older specs) and Delayed::Worker.delay_jobs = true left
#   behind make every later job (purge_later, smart annotation remapping, user assignment inheritance, ...)
#   be enqueued instead of run inline.
module GlobalStateGuard
  CHAINS = [%w(Activity create), %w(Activity initialize), %w(MyModule create)].freeze

  class << self
    def snapshot!
      @chains = CHAINS.to_h do |(model, event)|
        [[model, event], model.constantize.send(:get_callbacks, event.to_sym)]
      end
      @queue_adapter = ActiveJob::Base.queue_adapter
      @delay_jobs = Delayed::Worker.delay_jobs
    end

    def restore!
      return unless @chains

      @chains.each do |(model, event), chain|
        klass = model.constantize
        klass.send(:set_callbacks, event.to_sym, chain) unless klass.send(:get_callbacks, event.to_sym).equal?(chain)
      end
      ActiveJob::Base.queue_adapter = @queue_adapter unless ActiveJob::Base.queue_adapter.equal?(@queue_adapter)
      Delayed::Worker.delay_jobs = @delay_jobs
    end
  end
end

RSpec.configure do |config|
  config.before(:suite) { GlobalStateGuard.snapshot! }
  config.after { GlobalStateGuard.restore! }
end
