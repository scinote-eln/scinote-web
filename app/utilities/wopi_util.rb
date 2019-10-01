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
        next unless %w(view edit editnew wopitest).include?(name)

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
    action = if started_editing
               t('activities.wupi_file_editing.started')
             else
               t('activities.wupi_file_editing.finished')
             end
    if @assoc.class == Step
      default_step_items =
        { step: @asset.step.id,
          step_position: { id: @asset.step.id, value_for: 'position_plus_one' },
          asset_name: { id: @asset.id, value_for: 'file_name' },
          action: action }
      if @protocol.in_module?
        project = @protocol.my_module.experiment.project
        team = project.team
        type_of = :edit_wopi_file_on_step
        message_items = { my_module: @protocol.my_module.id }
      else
        type_of = :edit_wopi_file_on_step_in_repository
        project = nil
        team = @protocol.team
        message_items = { protocol: @protocol.id }
      end
      message_items = default_step_items.merge(message_items)
      Activities::CreateActivityService
        .call(activity_type: type_of,
              owner: current_user,
              subject: @protocol,
              team: team,
              project: project,
              message_items: message_items)
    elsif @assoc.class == Result
      Activities::CreateActivityService
        .call(activity_type: :edit_wopi_file_on_result,
              owner: current_user,
              subject: @asset.result,
              team: @my_module.experiment.project.team,
              project: @my_module.experiment.project,
              message_items: {
                result: @asset.result.id,
                asset_name: { id: @asset.id, value_for: 'file_name' },
                action: action
              })
    end
  end
end
