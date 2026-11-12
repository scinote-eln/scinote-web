# frozen_string_literal: true

require 'rails_helper'

describe ProtocolSerializer do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:routes) { Rails.application.routes.url_helpers }
  let(:viewer_role) { create :viewer_role }
  let(:protocol) do
    create :protocol, :in_repository_draft, team: team, added_by: user, name: 'Serialized', authors: 'Author',
                                            description: '<p>Hello <b>world</b></p>'
  end
  let(:result) { build_serializer(protocol).attributes }
  let(:urls) { result[:urls] }

  def build_serializer(record)
    acting_user = user
    described_class.new(record, scope: acting_user, scope_name: nil, user: acting_user).tap do |ser|
      ser.define_singleton_method(:current_user) { acting_user }
    end
  end

  def make_viewer(*assignables)
    UserAssignment.where(user: user, assignable: assignables).update_all(user_role_id: viewer_role.id)
  end

  before do
    user.update!(current_team_id: team.id)
    allow(Protocol).to receive(:content_locking_enabled?).and_return(false)
  end

  describe 'repository protocol' do
    it 'exposes the basic attributes' do
      expect(result).to include(
        id: protocol.id,
        name: 'Serialized',
        authors: 'Author',
        in_repository: true,
        published: false,
        archived: false,
        linked: false,
        has_draft: false,
        description_locked: protocol.description_locked,
        updated_at: protocol.updated_at.to_i,
        created_at_formatted: I18n.l(protocol.created_at, format: :full),
        updated_at_formatted: I18n.l(protocol.updated_at, format: :full),
        code: protocol.code,
        assignable_my_module_id: nil,
        assignable_my_module_name: nil,
        published_on_formatted: nil,
        created_from_version: nil
      )
      expect(result[:added_by][:name]).to eq user.full_name
      expect(result[:published_by]).to eq(avatar: nil, name: nil)
      expect(result[:version]).to eq protocol.version_number
    end

    it 'sanitizes the description and builds the view description' do
      expect(result[:description]).to include('Hello', '<b>world</b>')
      expect(result[:description_view]).to include('Hello', 'world')
    end

    it 'escapes keywords' do
      keyword = ProtocolKeyword.create!(name: 'k<b>1', team: team)
      protocol.protocol_keywords << keyword

      expect(result[:keywords]).to eq [{ label: 'k&lt;b&gt;1', value: 'k&lt;b&gt;1' }]
    end

    it 'builds management urls for the owner' do
      expect(urls).to include(
        steps_url: routes.steps_path(protocol_id: protocol.id),
        add_step_url: routes.protocol_steps_path(protocol_id: protocol.id),
        add_protocol_steps_url: routes.add_protocol_steps_protocol_steps_path(protocol),
        reorder_steps_url: routes.reorder_protocol_steps_url(protocol_id: protocol.id),
        update_protocol_name_url: routes.name_protocol_path(protocol),
        update_protocol_description_url: routes.description_protocol_path(protocol),
        update_protocol_authors_url: routes.authors_protocol_path(protocol),
        update_protocol_keywords_url: routes.keywords_protocol_path(protocol),
        delete_steps_url: routes.delete_steps_protocol_path(protocol),
        versions_modal_url: routes.versions_modal_protocol_path(protocol),
        print_protocol_url: routes.print_protocol_path(protocol),
        redirect_to_protocols: routes.protocols_path
      )
      expect(urls[:publish_url]).to eq routes.publish_protocol_path(protocol)
      expect(urls[:version_comment_url]).to eq routes.version_comment_protocol_path(protocol)
      expect(urls[:save_as_draft_url]).to be_nil
    end

    it 'has no task only urls' do
      expect(urls.values_at(:export_url, :load_from_repo_url, :save_to_repo_url, :unlink_url,
                            :revert_protocol_url, :update_protocol_url)).to all(be_nil)
      expect(result[:permissions]).to eq(can_manage_protocol_in_module: false)
    end

    it 'omits content locking urls when the feature is disabled' do
      expect(urls.values_at(:lock_all_steps_url, :unlock_all_steps_url, :update_description_locked_url)).to all(be_nil)
    end

    it 'adds content locking urls when the feature is enabled' do
      allow(Protocol).to receive(:content_locking_enabled?).and_return(true)

      expect(urls[:lock_all_steps_url]).to eq routes.lock_all_protocol_steps_path(protocol)
      expect(urls[:unlock_all_steps_url]).to eq routes.unlock_all_protocol_steps_path(protocol)
      expect(urls[:update_description_locked_url]).to eq routes.update_description_locked_protocol_path(protocol)
    end

    it 'only offers read urls to a viewer' do
      protocol
      make_viewer(team, protocol)

      expect(urls).to include(
        steps_url: routes.steps_path(protocol_id: protocol.id),
        print_protocol_url: routes.print_protocol_path(protocol),
        versions_modal_url: routes.versions_modal_protocol_path(protocol)
      )
      expect(urls.values_at(:add_step_url, :add_protocol_steps_url, :reorder_steps_url, :update_protocol_name_url,
                            :update_protocol_description_url, :update_protocol_authors_url,
                            :update_protocol_keywords_url, :delete_steps_url, :publish_url,
                            :version_comment_url)).to all(be_nil)
    end
  end

  describe 'published repository protocol' do
    let(:protocol) do
      create :protocol, :in_repository_published_original, team: team, added_by: user, name: 'Published',
                                                           published_by: user
    end

    it 'exposes publication data' do
      expect(result).to include(
        published: true,
        version: 1,
        published_on_formatted: I18n.l(protocol.published_on, format: :full),
        has_draft: false
      )
      expect(result[:published_by]).to eq(avatar: user.avatar_url(:icon_small), name: user.full_name)
    end

    it 'reports an existing draft' do
      create :protocol, :in_repository_draft, team: team, added_by: user, parent: protocol, version_number: 2

      expect(build_serializer(protocol.reload).attributes[:has_draft]).to be true
    end

    it 'offers save as draft to managers' do
      expect(urls[:save_as_draft_url]).to eq routes.save_as_draft_protocol_path(protocol)
    end

    it 'uses the parent code and version for published versions' do
      version = create :protocol, :in_repository_published_version, team: team, added_by: user, parent: protocol,
                                                                   version_number: 2, previous_version: protocol
      data = build_serializer(version).attributes

      expect(data[:code]).to eq protocol.code
      expect(data[:version]).to eq 2
      expect(data[:created_from_version]).to eq 1
      expect(data[:urls][:versions_modal]).to eq routes.versions_modal_protocol_path(protocol)
    end
  end

  describe 'task protocol' do
    let(:project) { create :project, team: team, created_by: user }
    let(:experiment) { create :experiment, project: project, created_by: user }
    let(:my_module) { create :my_module, experiment: experiment, created_by: user, name: 'Task A' }
    let(:protocol) { my_module.protocol }

    it 'is not in the repository and exposes the task' do
      expect(result).to include(in_repository: false, assignable_my_module_id: my_module.id,
                                assignable_my_module_name: 'Task A')
      expect(result[:permissions]).to eq(can_manage_protocol_in_module: true)
    end

    it 'builds task urls for the owner' do
      expect(urls).to include(
        export_url: routes.export_protocols_path(protocol_ids: protocol.id, my_module_id: my_module.id),
        load_from_repo_url: routes.load_from_repository_modal_protocol_path(protocol, format: :json),
        save_to_repo_url: routes.copy_to_repository_modal_protocol_path(protocol, format: :json),
        update_protocol_name_url: routes.protocol_my_module_path(my_module),
        update_protocol_description_url: routes.protocol_my_module_path(my_module),
        add_step_url: routes.protocol_steps_path(protocol_id: protocol.id),
        archive_steps_url: routes.archive_steps_protocol_path(protocol),
        reorder_steps_url: routes.reorder_protocol_steps_url(protocol_id: protocol.id)
      )
      expect(urls.values_at(:update_protocol_authors_url, :update_protocol_keywords_url, :delete_steps_url,
                            :publish_url, :unlink_url, :revert_protocol_url, :update_protocol_url)).to all(be_nil)
    end

    it 'hides management urls from a viewer' do
      protocol
      make_viewer(team, project, experiment, my_module)

      expect(result[:permissions]).to eq(can_manage_protocol_in_module: false)
      expect(urls[:export_url]).to eq routes.export_protocols_path(protocol_ids: protocol.id, my_module_id: my_module.id)
      expect(urls.values_at(:load_from_repo_url, :add_step_url, :archive_steps_url, :reorder_steps_url,
                            :update_protocol_name_url, :update_protocol_description_url)).to all(be_nil)
    end

    context 'when linked to a repository protocol' do
      let(:parent) do
        create :protocol, :in_repository_published_original, team: team, added_by: user, published_by: user
      end

      before { protocol.update!(protocol_type: :linked, parent: parent, linked_at: 1.day.ago, added_by: user) }

      it 'exposes linked state and unlink / revert urls' do
        expect(result[:linked]).to be true
        expect(urls[:unlink_url]).to eq routes.unlink_modal_protocol_path(protocol, format: :json)
        expect(urls[:revert_protocol_url]).to eq routes.revert_modal_protocol_path(protocol, format: :json)
      end

      it 'offers an update from the parent only when the parent is newer' do
        parent.update_columns(published_on: 1.minute.from_now)
        expect(urls[:update_protocol_url]).to eq routes.update_from_parent_modal_protocol_path(protocol, format: :json)

        parent.update_columns(published_on: 2.days.ago)
        protocol.update_columns(updated_at: 1.hour.ago)
        expect(build_serializer(protocol.reload).attributes[:urls][:update_protocol_url]).to be_nil
      end
    end
  end
end
