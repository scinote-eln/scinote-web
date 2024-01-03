# frozen_string_literal: true

module WopiUtil
  require 'open-uri'

  # Used for timestamp
  UNIX_EPOCH_IN_CLR_TICKS = 621355968000000000
  CLR_TICKS_PER_SECOND = 10000000

  DISCOVERY_TTL = 1.day
  DISCOVERY_TTL.freeze

  # For more explanation see this:
  # http://stackoverflow.com/questions/11888053/
  # convert-net-datetime-ticks-property-to-date-in-objective-c
  def convert_to_unix_timestamp(timestamp)
    Time.zone.at((timestamp - UNIX_EPOCH_IN_CLR_TICKS) / CLR_TICKS_PER_SECOND)
  end

  def get_action(extension, action)
    discovery = current_wopi_discovery
    discovery[:actions].find { |i| i[:extension] == extension && i[:action] == action }
  end

  def current_wopi_discovery
    initialize_discovery
  end

  # Verifies if proof from headers, X-WOPI-Proof/X-WOPI-OldProof was encrypted
  # with this discovery public key (two key possible old/new)
  def wopi_verify_proof(token, timestamp, signed_proof, signed_proof_old, url)
    discovery = current_wopi_discovery
    token_length = [token.length].pack('>N').bytes
    timestamp_bytes = [timestamp.to_i].pack('>Q').bytes.reverse
    timestamp_length = [timestamp_bytes.length].pack('>N').bytes
    url_length = [url.length].pack('>N').bytes

    expected_proof = token_length + token.bytes +
                     url_length + url.upcase.bytes +
                     timestamp_length + timestamp_bytes

    key = generate_key(discovery[:proof_key_mod], discovery[:proof_key_exp])
    old_key = generate_key(discovery[:proof_key_old_mod], discovery[:proof_key_old_exp])

    # Try all possible combiniations
    try_verification(expected_proof, signed_proof, key) ||
      try_verification(expected_proof, signed_proof_old, key) ||
      try_verification(expected_proof, signed_proof, old_key)
  end

  private

  # Currently only saves Excel, Word and PowerPoint view and edit actions
  def initialize_discovery
    Rails.cache.fetch(:wopi_discovery, expires_in: DISCOVERY_TTL) do
      @doc = Nokogiri::XML(Net::HTTP.get(URI(ENV.fetch('WOPI_DISCOVERY_URL', nil))))
      discovery_json = {}
      key = @doc.xpath('//proof-key')
      discovery_json[:proof_key_mod] = key.xpath('@modulus').first.value
      discovery_json[:proof_key_exp] = key.xpath('@exponent').first.value
      discovery_json[:proof_key_old_mod] = key.xpath('@oldmodulus').first.value
      discovery_json[:proof_key_old_exp] = key.xpath('@oldexponent').first.value
      discovery_json[:actions] = []
      wopi_net_zone_name = ENV.fetch('WOPI_NET_ZONE_NAME', nil)
      wopi_apps_path = wopi_net_zone_name.present? ? "//net-zone[@name='#{wopi_net_zone_name}']//app" : '//app'

      @doc.xpath(wopi_apps_path).each do |app|
        app_name = app.xpath('@name').first.value
        next unless %w(Excel Word PowerPoint WopiTest).include?(app_name)

        icon = app.xpath('@favIconUrl').first.value

        app.xpath('action').each do |action|
          action_name = action.xpath('@name').first.value
          next unless %w(view edit editnew embedview wopitest).include?(action_name)

          action_json = {}
          action_json[:icon] = icon
          action_json[:action] = action_name
          action_json[:extension] = action.xpath('@ext').first.value
          action_json[:urlsrc] = action.xpath('@urlsrc').first.value
          discovery_json[:actions].push(action_json)
        end
      end
      discovery_json
    end
  rescue StandardError => e
    Rails.logger.warn 'WOPI: initialization failed: ' + e.message
    e.backtrace.each { |line| Rails.logger.error line }
  end

  # Generates a public key from given modulus and exponent
  def generate_key(modulus, exponent)
    mod = Base64.decode64(modulus).unpack1('H*').to_i(16)
    exp = Base64.decode64(exponent).unpack1('H*').to_i(16)

    seq = OpenSSL::ASN1::Sequence.new([OpenSSL::ASN1::Integer.new(mod),
                                       OpenSSL::ASN1::Integer.new(exp)])
    OpenSSL::PKey::RSA.new(seq.to_der)
  end

  # Verify if decrypting signed_proof with public_key equals to expected_proof
  def try_verification(expected_proof, signed_proof_b64, public_key)
    signed_proof = Base64.decode64(signed_proof_b64)
    public_key.verify(OpenSSL::Digest::SHA256.new, signed_proof,
                      expected_proof.pack('c*'))
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
    elsif @assoc.is_a?(RepositoryCell)
      repository = @assoc.repository_row.repository
      Activities::CreateActivityService
        .call(activity_type: :edit_wopi_file_on_inventory_item,
              owner: current_user,
              subject: repository,
              team: repository.team,
              message_items: {
                repository: repository.id,
                repository_row: @assoc.repository_row.id,
                asset_name: { id: @asset.id, value_for: 'file_name' },
                action: action
              })
    end
  end
end
