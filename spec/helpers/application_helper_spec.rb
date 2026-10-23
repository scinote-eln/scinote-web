# frozen_string_literal: true

require 'rails_helper'

describe ApplicationHelper, type: :helper do
  let(:user) { create(:user) }
  let(:team) { create(:team) }

  def stub_settings(values)
    allow(ApplicationSettings).to receive(:instance).and_return(double('settings', values: values))
  end

  def annotation(user)
    "[@#{user.full_name}~#{user.id.base62_encode}]"
  end

  describe 'page helpers' do
    it 'detects module pages for my_modules and my_module_repositories controllers' do
      allow(helper).to receive(:controller_name).and_return('my_modules')
      expect(helper.module_page?).to be true
      allow(helper).to receive(:controller_name).and_return('my_module_repositories')
      expect(helper.module_page?).to be true
      allow(helper).to receive(:controller_name).and_return('projects')
      expect(helper.module_page?).to be false
    end

    it 'detects the experiment page' do
      allow(helper).to receive(:controller_name).and_return('experiments')
      expect(helper.experiment_page?).to be true
      allow(helper).to receive(:controller_name).and_return('projects')
      expect(helper.experiment_page?).to be false
    end

    it 'detects the project page only for show and experiment_archive actions' do
      allow(helper).to receive(:controller_name).and_return('projects')
      allow(helper).to receive(:action_name).and_return('show')
      expect(helper.project_page?).to be true
      allow(helper).to receive(:action_name).and_return('experiment_archive')
      expect(helper.project_page?).to be true
      allow(helper).to receive(:action_name).and_return('index')
      expect(helper.project_page?).to be false
    end

    it 'detects the all projects page only for index and archive actions' do
      allow(helper).to receive(:controller_name).and_return('projects')
      allow(helper).to receive(:action_name).and_return('archive')
      expect(helper.all_projects_page?).to be true
      allow(helper).to receive(:action_name).and_return('show')
      expect(helper.all_projects_page?).to be false
    end

    it 'detects module repository page only when a repository is assigned' do
      allow(helper).to receive(:controller_name).and_return('my_modules')
      helper.instance_variable_set(:@repository, nil)
      expect(helper.module_repository_page?).to be false
      helper.instance_variable_set(:@repository, Object.new)
      expect(helper.module_repository_page?).to be true
    end

    it 'returns the logo url' do
      expect(helper.application_logo_url).to eq '/images/scinote_logo.svg'
    end

    it 'returns nil grey background flag when controller or action is missing' do
      allow(helper).to receive(:controller_name).and_return(nil)
      expect(helper.show_grey_background?).to be false
    end

    it 'enables the grey background for configured controller/action pairs only' do
      allow(helper).to receive(:controller_name).and_return('protocols')
      allow(helper).to receive(:action_name).and_return('show')
      expect(helper.show_grey_background?).to be true

      allow(helper).to receive(:action_name).and_return('index')
      expect(helper.show_grey_background?).to be false
    end
  end

  describe 'flash helpers' do
    it 'accepts only known flash types' do
      %w(success warning alert error notice).each do |type|
        expect(helper.displayable_flash_type?(type)).to be true
      end
      expect(helper.displayable_flash_type?('debug')).to be false
    end

    it 'maps flash types to bootstrap alert classes' do
      expect(helper.flash_alert_class('success')).to eq 'alert-success'
      expect(helper.flash_alert_class('warning')).to eq 'alert-warning'
      expect(helper.flash_alert_class('error')).to eq 'alert-danger'
      expect(helper.flash_alert_class('alert')).to eq 'alert-danger'
      expect(helper.flash_alert_class('notice')).to eq 'alert-info'
    end

    it 'maps flash types to icons' do
      expect(helper.flash_icon_class('error')).to eq 'fa-exclamation-triangle'
      expect(helper.flash_icon_class('warning')).to eq 'fa-exclamation-triangle'
      expect(helper.flash_icon_class('success')).to eq 'fa-check-circle'
    end
  end

  describe '#display_tooltip' do
    it 'returns an empty string for a missing message' do
      expect(helper.display_tooltip(nil)).to eq ''
    end

    it 'returns the stripped message untouched when it fits' do
      expect(helper.display_tooltip("  short name  ")).to eq 'short name'
    end

    it 'truncates the text and adds a tooltip with the full message when too long' do
      long = 'a' * 40
      html = helper.display_tooltip(long, 10)

      expect(html).to include('class="modal-tooltip"', 'class="modal-tooltiptext"')
      expect(html).to include('a' * 40)
      expect(html).to include('...')
    end
  end

  describe '#custom_link_open_new_tab' do
    it 'adds target blank to anchors' do
      expect(helper.custom_link_open_new_tab('<a href="x">y</a>')).to eq '<a target=_blank href="x">y</a>'
    end
  end

  describe '#smart_annotation_notification' do
    let(:subject_record) { create(:repository, team: team, created_by: user) }

    it 'does nothing when the new text is blank' do
      expect(GeneralNotification).not_to receive(:send_notifications)
      helper.smart_annotation_notification(new_text: '', subject: subject_record)
    end

    it 'notifies only users newly mentioned in the text and skips unknown users' do
      other = create(:user)
      already = create(:user)
      unknown_id = (User.maximum(:id) || 0) + 1000
      old_text = annotation(already)
      new_text = "#{old_text} #{annotation(other)} [@ghost~#{unknown_id.base62_encode}]"

      expect(GeneralNotification).to receive(:send_notifications).once do |payload|
        expect(payload).to include(
          type: :smart_annotation_added,
          subject_id: subject_record.id,
          subject_class: 'Repository',
          user_id: other.id
        )
      end

      helper.smart_annotation_notification(old_text: old_text,
                                           new_text: new_text,
                                           subject: subject_record,
                                           title: 'Mentioned')
    end

    it 'defaults the notification title to a translation key' do
      expect(helper).to receive(:generate_annotation_notification)
        .with(user, :title_must_be_present, subject_record)
      helper.smart_annotation_notification(new_text: annotation(user), subject: subject_record)
    end
  end

  describe '#generate_annotation_notification' do
    it 'sends a sanitized smart annotation notification to the target user' do
      subject_record = create(:repository, team: team, created_by: user)
      expect(GeneralNotification).to receive(:send_notifications).with(
        hash_including(
          type: :smart_annotation_added,
          title: 'Hello',
          subject_name: subject_record.name,
          user_id: user.id
        )
      )
      helper.generate_annotation_notification(user, 'Hello', subject_record)
    end
  end

  describe '#smart_annotation_parser' do
    let(:owner_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.owner')) }
    let(:project) { create(:project, team: team, created_by: user) }

    before do
      allow(helper).to receive(:current_user).and_return(user)
      user.update!(current_team_id: team.id)
      create_user_assignment(team, owner_role, user)
      create_user_assignment(project, owner_role, user)
    end

    it 'resolves project and user annotations of the text with real records' do
      text = "see [#Proj~prj~#{project.id.base62_encode}] by #{annotation(user)}"

      result = helper.smart_annotation_parser(text, team)

      expect(result).to include "<span class=\"sa-type\">Prj</span>#{project.name}</a>"
      expect(result).to include "href=\"#{Rails.application.routes.url_helpers.experiments_path(project_id: project)}\""
      expect(result).not_to include '[#Proj~prj~'
      expect(result).not_to include '[@'
      expect(result).to include user.full_name
    end

    it 'replaces a project the user cannot read with the private placeholder' do
      other_project = create(:project, team: create(:team), created_by: create(:user))
      text = "[#Secret~prj~#{other_project.id.base62_encode}]"

      result = helper.smart_annotation_parser(text, team)

      expect(result).to include I18n.t('smart_annotations.private.project')
      expect(result).not_to include other_project.name
    end

    it 'drops a team argument that is not a Team and still parses the text' do
      text = "[#Proj~prj~#{project.id.base62_encode}]"

      result = helper.smart_annotation_parser(text, '{nil, []}')

      expect(result).to include "<span class=\"sa-type\">Prj</span>#{project.name}</a>"
    end

    it 'forwards the team and the flags to the user popover renderer' do
      # collaborator stubbed because the popover partial needs a full controller render context
      expect(helper).to receive(:popover_for_user_name)
        .with(user, team, false, false, true).and_return('<popover/>')

      expect(helper.smart_annotation_parser(annotation(user), team, true, true)).to eq '<popover/>'
    end
  end

  describe '#smart_annotation_filter_resources' do
    it 'renders the tag to html for the current user and the given team' do
      allow(helper).to receive(:current_user).and_return(user)
      tag_to_html = double('TagToHtml', html: 'resource')
      expect(SmartAnnotations::TagToHtml).to receive(:new)
        .with(user, team, 'raw', true).and_return(tag_to_html)

      expect(helper.smart_annotation_filter_resources('raw', team, preview_repository: true))
        .to eq 'resource'
    end
  end

  describe '#smart_annotation_filter_users' do
    it 'replaces user annotations with popovers and leaves unknown users out' do
      allow(helper).to receive(:popover_for_user_name).and_return('<popover/>')
      ghost = (User.maximum(:id) || 0) + 1000
      text = "hi #{annotation(user)} and [@ghost~#{ghost.base62_encode}]"

      result = helper.smart_annotation_filter_users(text, team)

      # unknown users are dropped from the text by the gsub block returning nil
      expect(result).to eq 'hi <popover/> and '
    end

    it 'passes the flags to the popover renderer' do
      expect(helper).to receive(:popover_for_user_name)
        .with(user, team, false, false, true).and_return('<popover/>')
      helper.smart_annotation_filter_users(annotation(user), team, base64_encoded_imgs: true)
    end
  end

  describe '#popover_for_user_name' do
    it 'renders the user container partial and removes new lines' do
      expect(controller).to receive(:render_to_string).with(
        partial: 'shared/atwho_user_container',
        locals: hash_including(user: user, team: team, skip_avatar: true,
                               skip_user_status: false, base64_encoded_imgs: false),
        formats: :html
      ).and_return("<div>\nuser\n</div>")

      expect(helper.popover_for_user_name(user, team, false, true)).to eq '<div>user</div>'
    end
  end

  describe '#user_avatar_absolute_url' do
    it 'returns the attached avatar as base64 when requested' do
      allow(user.avatar).to receive(:attached?).and_return(true)
      allow(user).to receive(:avatar_variant).with(:thumb).and_return(:avatar_variant)
      expect(user).to receive(:convert_variant_to_base64).with(:avatar_variant)
                                                         .and_return('data:image/png;base64,AAAA')

      expect(helper.user_avatar_absolute_url(user, :thumb, true)).to eq 'data:image/png;base64,AAAA'
    end

    it 'returns an expiring url of the attached avatar variant' do
      processed = double('processed')
      expect(processed).to receive(:url).with(expires_in: Constants::URL_LONG_EXPIRE_TIME)
                                        .and_return('https://storage.example/avatar.png')
      allow(user.avatar).to receive(:attached?).and_return(true)
      allow(user).to receive(:avatar_variant).with(:thumb).and_return(double('variant', processed: processed))

      expect(helper.user_avatar_absolute_url(user, :thumb)).to eq 'https://storage.example/avatar.png'
    end

    it 'returns the default avatar path for the requested style when there is no avatar' do
      expect(helper.user_avatar_absolute_url(user, :thumb)).to eq '/images/thumb/missing.svg'
    end

    it 'returns the default avatar as base64 svg when requested' do
      url = helper.user_avatar_absolute_url(user, :thumb, true)
      expect(url).to start_with('data:image/svg+xml;base64,')
    end

    it 'falls back to the missing avatar and logs when the avatar cannot be resolved' do
      allow(user).to receive(:avatar_variant).and_raise(StandardError, 'boom')
      expect(Rails.logger).to receive(:error).with('boom')

      expect(helper.user_avatar_absolute_url(user, :thumb)).to eq 'icon_small/missing.svg'
    end
  end

  describe 'SSO and settings helpers' do
    it 'reads sso_enabled from the environment' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('SSO_ENABLED').and_return('true')
      expect(helper.sso_enabled?).to be true
      allow(ENV).to receive(:[]).with('SSO_ENABLED').and_return('false')
      expect(helper.sso_enabled?).to be false
    end

    it 'reads wopi_enabled from the environment' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('WOPI_ENABLED').and_return('true')
      expect(helper.wopi_enabled?).to be true
    end

    it 'reports each provider from the application settings' do
      stub_settings('okta' => { 'enabled' => true }, 'saml' => { 'enabled' => false },
                    'openid_connect' => { 'enabled' => true },
                    'azure_ad_apps' => [{ 'enabled' => true }])

      expect(helper.okta_enabled?).to be true
      expect(helper.saml_enabled?).to be false
      expect(helper.openid_connect_enabled?).to be true
      expect(helper.azure_ad_enabled?).to be true
      expect(helper.sso_provider_enabled?).to be true
    end

    it 'reports no sso provider when none is enabled' do
      stub_settings('okta' => { 'enabled' => false }, 'azure_ad_apps' => [])

      expect(helper.azure_ad_enabled?).to be_falsey
      expect(helper.sso_provider_enabled?).to be false
    end

    it 'returns the login disclaimer from the settings' do
      stub_settings('login_disclaimer' => { 'title' => 'Notice', 'body' => 'Body', 'action' => 'Ok' })

      expect(helper.login_disclaimer).to eq('title' => 'Notice', 'body' => 'Body', 'action' => 'Ok')
    end
  end

  describe '#wopi_file_edit_button_status' do
    it 'allows editing for supported wopi formats with no title' do
      expect(helper.wopi_file_edit_button_status(double(file_name: 'a.docx'))).to eq [true, '']
    end

    it 'returns the text formats title for non editable text files' do
      expect(helper.wopi_file_edit_button_status(double(file_name: 'a.rtf')))
        .to eq [false, I18n.t('assets.wopi_supported_text_formats_title')]
    end

    it 'returns the table formats title for non editable table files' do
      expect(helper.wopi_file_edit_button_status(double(file_name: 'a.csv')))
        .to eq [false, I18n.t('assets.wopi_supported_table_formats_title')]
    end

    it 'returns the presentation formats title for everything else' do
      expect(helper.wopi_file_edit_button_status(double(file_name: 'a.pot')))
        .to eq [false, I18n.t('assets.wopi_supported_presentation_formats_title')]
    end
  end

  describe '#create_2fa_qr_code' do
    it 'assigns a new 2FA secret and renders a QR code svg' do
      svg = helper.create_2fa_qr_code(user)

      expect(user.reload.otp_secret).to be_present
      expect(svg).to include('<svg')
    end
  end
end
