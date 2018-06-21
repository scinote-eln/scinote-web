module WopiUtil
  require 'open-uri'

  # Used for timestamp
  UNIX_EPOCH_IN_CLR_TICKS = 621355968000000000
  CLR_TICKS_PER_SECOND = 10000000

  DISCOVERY_TTL = 1.days
  DISCOVERY_TTL.freeze

  # For more explanation see this:
  # http://stackoverflow.com/questions/11888053/
  # convert-net-datetime-ticks-property-to-date-in-objective-c
  def convert_to_unix_timestamp(timestamp)
    Time.at((timestamp - UNIX_EPOCH_IN_CLR_TICKS) / CLR_TICKS_PER_SECOND)
  end

  def get_action(extension, activity)
    current_wopi_discovery
    WopiAction.find_action(extension, activity)
  end

  def current_wopi_discovery
    discovery = WopiDiscovery.first
    return discovery if discovery && discovery.expires >= Time.now.to_i
    initialize_discovery(discovery)
  end

  private

  # Currently only saves Excel, Word and PowerPoint view and edit actions
  def initialize_discovery(discovery)
    Rails.logger.warn 'Initializing discovery'
    discovery.destroy if discovery

    @doc = Nokogiri::XML(Kernel.open(ENV['WOPI_DISCOVERY_URL']))

    discovery = WopiDiscovery.new
    discovery.expires = Time.now.to_i + DISCOVERY_TTL
    key = @doc.xpath('//proof-key')
    discovery.proof_key_mod = key.xpath('@modulus').first.value
    discovery.proof_key_exp = key.xpath('@exponent').first.value
    discovery.proof_key_old_mod = key.xpath('@oldmodulus').first.value
    discovery.proof_key_old_exp = key.xpath('@oldexponent').first.value
    discovery.save!

    @doc.xpath('//app').each do |app|
      app_name = app.xpath('@name').first.value
      next unless %w(Excel Word PowerPoint WopiTest).include?(app_name)

      wopi_app = WopiApp.new
      wopi_app.name = app.xpath('@name').first.value
      wopi_app.icon = app.xpath('@favIconUrl').first.value
      wopi_app.wopi_discovery_id = discovery.id
      wopi_app.save!
      app.xpath('action').each do |action|
        name = action.xpath('@name').first.value
        next unless %w(view edit wopitest).include?(name)
        wopi_action = WopiAction.new
        wopi_action.action = name
        wopi_action.extension = action.xpath('@ext').first.value
        wopi_action.urlsrc = action.xpath('@urlsrc').first.value
        wopi_action.wopi_app_id = wopi_app.id
        wopi_action.save!
      end
    end
    discovery
  rescue => e
    Rails.logger.warn 'WOPI: initialization failed: ' + e.message
    e.backtrace.each { |line| Rails.logger.error line }
    discovery = WopiDiscovery.first
    discovery.destroy if discovery
  end

  def create_wopi_file_activity(current_user, started_editing)
    if @assoc.class == Step
      activity = Activity.new(
        type_of: :start_edit_wopi_file,
        user: current_user,
        message: t(
          started_editing ? 'activities.start_edit_wopi_file_step' :
                            'activities.unlock_wopi_file_step',
          user: current_user.full_name,
          file: @asset.file_file_name,
          step: @asset.step.position + 1,
          step_name: @asset.step.name
        )
      )

      if @protocol.in_module?
        activity.my_module = @protocol.my_module
        activity.project = @protocol.my_module.experiment.project
      end

      activity.save
    elsif @assoc.class == Result
      Activity.create(
        type_of: :start_edit_wopi_file,
        user: current_user,
        project: @my_module.experiment.project,
        experiment: @my_module.experiment,
        my_module: @my_module,
        message: t(
          started_editing ? 'activities.start_edit_wopi_file_result' :
                            'activities.unlock_wopi_file_result',
          user: current_user.full_name,
          file: @asset.file_file_name,
          result: @asset.result.name
        )
      )
    end
  end
end
