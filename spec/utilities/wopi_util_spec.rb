# frozen_string_literal: true

require 'rails_helper'

describe WopiUtil do
  let(:host_class) do
    Class.new do
      include AbstractController::Translation
      include WopiUtil
    end
  end
  let(:util) { host_class.new }
  let(:discovery_url) { 'https://wopi.test/hosting/discovery' }

  around do |example|
    saved_env = %w(WOPI_DISCOVERY_URL WOPI_NET_ZONE_NAME).to_h { |key| [key, ENV.fetch(key, nil)] }
    ENV['WOPI_DISCOVERY_URL'] = discovery_url
    ENV.delete('WOPI_NET_ZONE_NAME')
    example.run
  ensure
    saved_env.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end

  before(:all) do
    @current_key = OpenSSL::PKey::RSA.new(2048)
    @old_key = OpenSSL::PKey::RSA.new(2048)
    @unrelated_key = OpenSSL::PKey::RSA.new(2048)
  end

  # Builds a discovery document in the WOPI format with the given proof keys
  # and a set of apps. Proof key attributes are base64 of big-endian bytes.
  def discovery_xml
    <<~XML
      <?xml version="1.0" encoding="utf-8"?>
      <wopi-discovery>
        <net-zone name="internal-https">
          <app name="Word" favIconUrl="https://wopi.test/word.ico">
            <action name="view" ext="docx" urlsrc="https://wopi.test/word/view?"/>
            <action name="edit" ext="docx" urlsrc="https://wopi.test/word/edit?"/>
            <action name="convert" ext="doc" urlsrc="https://wopi.test/word/convert?"/>
          </app>
          <app name="Visio" favIconUrl="https://wopi.test/visio.ico">
            <action name="view" ext="vsdx" urlsrc="https://wopi.test/visio/view?"/>
          </app>
        </net-zone>
        <net-zone name="other-zone">
          <app name="Excel" favIconUrl="https://wopi.test/excel.ico">
            <action name="view" ext="xlsx" urlsrc="https://wopi.test/excel/view?"/>
          </app>
        </net-zone>
        <proof-key value="ignored" modulus="#{proof_modulus}" exponent="#{proof_exponent}"
                   oldvalue="ignored" oldmodulus="#{old_proof_modulus}" oldexponent="#{old_proof_exponent}"/>
      </wopi-discovery>
    XML
  end

  def proof_modulus
    Base64.strict_encode64(@current_key.n.to_s(2))
  end

  def proof_exponent
    Base64.strict_encode64(@current_key.e.to_s(2))
  end

  def old_proof_modulus
    Base64.strict_encode64(@old_key.n.to_s(2))
  end

  def old_proof_exponent
    Base64.strict_encode64(@old_key.e.to_s(2))
  end

  # Byte layout of the WOPI proof: 4-byte length + token, 4-byte length +
  # upper-cased url, 4-byte length + 8-byte big-endian timestamp.
  def expected_proof_bytes(token, timestamp, url)
    [token.length].pack('N') + token.b +
      [url.length].pack('N') + url.upcase.b +
      [8].pack('N') + [timestamp].pack('Q>')
  end

  def sign_proof(key, token:, timestamp:, url:)
    Base64.strict_encode64(key.sign(OpenSSL::Digest::SHA256.new,
                                    expected_proof_bytes(token, timestamp, url)))
  end

  def stub_discovery(zone_name: nil)
    ENV['WOPI_NET_ZONE_NAME'] = zone_name if zone_name
    allow(Net::HTTP).to receive(:get).and_return(discovery_xml)
  end

  describe '#convert_to_unix_timestamp' do
    it 'converts .NET ticks to a Time in the app time zone' do
      ticks = (1_700_000_000 * WopiUtil::CLR_TICKS_PER_SECOND) + WopiUtil::UNIX_EPOCH_IN_CLR_TICKS

      expect(util.convert_to_unix_timestamp(ticks)).to eq Time.zone.at(1_700_000_000)
    end

    it 'maps the .NET epoch to the Unix epoch' do
      expect(util.convert_to_unix_timestamp(WopiUtil::UNIX_EPOCH_IN_CLR_TICKS)).to eq Time.zone.at(0)
    end
  end

  describe '#current_wopi_discovery' do
    it 'reads the proof keys from the discovery document' do
      stub_discovery

      discovery = util.current_wopi_discovery

      expect(discovery[:proof_key_mod]).to eq proof_modulus
      expect(discovery[:proof_key_exp]).to eq proof_exponent
      expect(discovery[:proof_key_old_mod]).to eq old_proof_modulus
      expect(discovery[:proof_key_old_exp]).to eq old_proof_exponent
    end

    it 'keeps only the whitelisted apps and actions from every net zone when no zone is configured' do
      stub_discovery

      actions = util.current_wopi_discovery[:actions]

      expect(actions.map { |a| [a[:extension], a[:action]] })
        .to contain_exactly(%w(docx view), %w(docx edit), %w(xlsx view))
    end

    it 'restricts the apps to the configured net zone' do
      stub_discovery(zone_name: 'internal-https')

      actions = util.current_wopi_discovery[:actions]

      expect(actions.map { |a| [a[:extension], a[:action]] })
        .to contain_exactly(%w(docx view), %w(docx edit))
    end

    it 'stores the app favicon and url source for each action' do
      stub_discovery

      view = util.current_wopi_discovery[:actions].find { |a| a[:extension] == 'docx' && a[:action] == 'view' }

      expect(view).to eq(
        icon: 'https://wopi.test/word.ico',
        action: 'view',
        extension: 'docx',
        urlsrc: 'https://wopi.test/word/view?'
      )
    end
  end

  describe '#get_action' do
    it 'returns the matching action for an extension' do
      stub_discovery

      action = util.get_action('docx', 'edit')

      expect(action).to include(action: 'edit', extension: 'docx', urlsrc: 'https://wopi.test/word/edit?')
    end

    it 'returns nil when the extension has no action of that type' do
      stub_discovery

      expect(util.get_action('docx', 'embedview')).to be_nil
    end

    it 'returns nil for an action that is not whitelisted' do
      stub_discovery

      expect(util.get_action('doc', 'convert')).to be_nil
    end

    it 'returns nil for an app that is outside the configured net zone' do
      stub_discovery(zone_name: 'internal-https')

      expect(util.get_action('xlsx', 'view')).to be_nil
    end

    # bug: initialize_discovery rescues the fetch error and returns the backtrace Array,
    # so get_action raises TypeError instead of reporting that no action is available
    it 'returns nil when the discovery document cannot be fetched' do
      pending 'bug: get_action returns nil when the discovery document cannot be fetched'
      allow(Net::HTTP).to receive(:get).and_raise(SocketError, 'getaddrinfo failed')

      expect(util.get_action('docx', 'view')).to be_nil
    end
  end

  describe '#wopi_verify_proof' do
    let(:token) { 'access-token-123' }
    let(:url) { 'https://scinote.test/wopi/files/42' }
    let(:timestamp) { 1_700_000_000 }

    before { stub_discovery }

    it 'accepts a proof signed with the current key' do
      signature = sign_proof(@current_key, token: token, timestamp: timestamp, url: url)

      expect(util.wopi_verify_proof(token, timestamp, signature, nil, url)).to be true
    end

    it 'accepts a proof signed with the current key when it arrives in the old-proof header' do
      signature = sign_proof(@current_key, token: token, timestamp: timestamp, url: url)
      unrelated = sign_proof(@unrelated_key, token: token, timestamp: timestamp, url: url)

      expect(util.wopi_verify_proof(token, timestamp, unrelated, signature, url)).to be true
    end

    it 'accepts a proof signed with the old key' do
      signature = sign_proof(@old_key, token: token, timestamp: timestamp, url: url)
      unrelated = sign_proof(@unrelated_key, token: token, timestamp: timestamp, url: url)

      expect(util.wopi_verify_proof(token, timestamp, signature, unrelated, url)).to be true
    end

    it 'rejects a proof signed by an unrelated key' do
      signature = sign_proof(@unrelated_key, token: token, timestamp: timestamp, url: url)

      expect(util.wopi_verify_proof(token, timestamp, signature, signature, url)).to be false
    end

    it 'rejects a valid signature when the url differs' do
      signature = sign_proof(@current_key, token: token, timestamp: timestamp, url: url)

      expect(util.wopi_verify_proof(token, timestamp, signature, signature, 'https://scinote.test/wopi/files/43'))
        .to be false
    end

    it 'rejects a valid signature when the timestamp was tampered with' do
      signature = sign_proof(@current_key, token: token, timestamp: timestamp, url: url)

      expect(util.wopi_verify_proof(token, timestamp + 1, signature, signature, url)).to be false
    end

    it 'rejects a valid signature when the access token differs' do
      signature = sign_proof(@current_key, token: token, timestamp: timestamp, url: url)

      expect(util.wopi_verify_proof('other-token', timestamp, signature, signature, url)).to be false
    end
  end

  describe '#create_wopi_file_activity' do
    let(:user) { create :user }
    let(:team) { create :team, created_by: user }
    let(:project) { create :project, team: team, created_by: user }
    let(:experiment) { create :experiment, project: project, created_by: user }
    let(:my_module) { create :my_module, experiment: experiment, created_by: user }
    let(:started) { I18n.t('activities.wopi_file_editing.started') }
    let(:finished) { I18n.t('activities.wopi_file_editing.finished') }

    before { allow(Activities::CreateActivityService).to receive(:call) }

    def host_with(assoc:, asset:, **extras)
      host = host_class.new
      host.instance_variable_set(:@assoc, assoc)
      host.instance_variable_set(:@asset, asset)
      extras.each { |name, value| host.instance_variable_set("@#{name}", value) }
      host
    end

    it 'logs a step edit inside a task protocol against the task and project' do
      protocol = create :protocol, my_module: my_module, team: team
      step = create :step, protocol: protocol, user: user
      asset = create(:step_asset, step: step).asset.reload

      host_with(assoc: step, asset: asset, protocol: protocol, my_module: my_module)
        .send(:create_wopi_file_activity, user, true)

      expect(Activities::CreateActivityService).to have_received(:call).with(
        activity_type: :edit_wopi_file_on_step,
        owner: user,
        subject: protocol,
        team: team,
        project: project,
        message_items: hash_including(
          my_module: my_module.id,
          step: step.id,
          action: started
        )
      )
    end

    it 'logs a step edit inside a repository protocol without a project' do
      repo_protocol = create :protocol, :in_repository_draft, team: team, added_by: user, name: 'Repo protocol'
      step = create :step, protocol: repo_protocol, user: user
      asset = create(:step_asset, step: step).asset.reload

      host_with(assoc: step, asset: asset, protocol: repo_protocol)
        .send(:create_wopi_file_activity, user, false)

      expect(Activities::CreateActivityService).to have_received(:call).with(
        activity_type: :edit_wopi_file_on_step_in_repository,
        owner: user,
        subject: repo_protocol,
        team: team,
        project: nil,
        message_items: hash_including(protocol: repo_protocol.id, action: finished)
      )
    end

    it 'logs an edit of a result file with the result and its project' do
      result = create :result, my_module: my_module, user: user
      asset = create(:result_asset, result: result).asset.reload

      host_with(assoc: result, asset: asset, my_module: my_module)
        .send(:create_wopi_file_activity, user, true)

      expect(Activities::CreateActivityService).to have_received(:call).with(
        activity_type: :edit_wopi_file_on_result,
        owner: user,
        subject: result,
        team: team,
        project: project,
        message_items: hash_including(result: result.id, action: started)
      )
    end

    it 'logs an edit of a result template file with the template protocol' do
      template = create :result_template, protocol: create(:protocol, :in_repository_draft, team: team, added_by: user),
                                        user: user
      asset = create(:result_asset, result: template).asset.reload

      host_with(assoc: template, asset: asset).send(:create_wopi_file_activity, user, false)

      expect(Activities::CreateActivityService).to have_received(:call).with(
        activity_type: :edit_wopi_file_on_result_template,
        owner: user,
        subject: template,
        team: team,
        project: nil,
        message_items: hash_including(result_template: template.id, protocol: template.protocol.id, action: finished)
      )
    end
  end
end
