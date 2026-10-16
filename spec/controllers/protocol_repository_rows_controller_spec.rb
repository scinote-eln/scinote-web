# frozen_string_literal: true

require 'rails_helper'

describe ProtocolRepositoryRowsController, type: :controller do
  login_user

  include_context 'reference_project_structure', { team_role: :owner }

  let!(:protocol) { create :protocol, :in_repository_draft, team: team, added_by: user }
  let!(:repository) { create :repository, team: team, created_by: user, name: 'Inventory' }
  let!(:row) { create :repository_row, repository: repository, created_by: user, name: 'Row one' }
  let!(:other_row) { create :repository_row, repository: repository, created_by: user, name: 'Row two' }
  let(:json) { JSON.parse(response.body) }

  before { user.update!(current_team_id: team.id) }

  describe 'GET index' do
    let!(:assigned) { protocol.protocol_repository_rows.create!(repository_row: row) }

    it 'lists the assigned rows as json' do
      get :index, params: { protocol_id: protocol.id }, format: :json

      expect(response).to have_http_status(:ok)
      expect(json['data'].size).to eq 1
      attributes = json['data'].first['attributes']
      expect(attributes).to include('name' => 'Row one', 'repository_name' => 'Inventory', 'archived' => false)
      expect(attributes['row_url']).to eq repository_repository_row_path(repository, row)
    end

    it 'renders html' do
      get :index, params: { protocol_id: protocol.id }

      expect(response).to have_http_status(:ok)
      expect(assigns(:active_tab)).to eq :repository_rows
      expect(assigns(:inline_editable_title_config)[:path_to_update]).to eq name_protocol_path(protocol)
      expect(assigns(:breadcrumbs_items).map { |i| i[:label] }).to eq [I18n.t('breadcrumbs.protocols'), protocol.name]
    end

    it 'labels breadcrumbs as archived for archived views' do
      get :index, params: { protocol_id: protocol.id, view_mode: 'archived' }

      expect(assigns(:breadcrumbs_items).first[:label]).to start_with(I18n.t('labels.archived'))
    end

    it 'returns 404 for an unknown protocol' do
      get :index, params: { protocol_id: -1 }, format: :json

      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 for a protocol of another team' do
      foreign = create :protocol, :in_repository_draft, added_by: create(:user)
      get :index, params: { protocol_id: foreign.id }, format: :json

      expect(response).to have_http_status(:not_found)
    end

    it 'returns forbidden without read permissions' do
      allow(controller).to receive(:can_read_protocol_in_repository?).and_return(false)
      get :index, params: { protocol_id: protocol.id }, format: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST create' do
    let(:action) { post :create, params: { protocol_id: protocol.id, repository_row_ids: [row.id, other_row.id] } }

    it 'assigns the rows and logs activities' do
      expect { action }.to change { protocol.protocol_repository_rows.count }.by(2)
                       .and change { Activity.where(type_of: :protocol_repository_item_added).count }.by(2)

      expect(response).to have_http_status(:ok)
      expect(protocol.protocol_repository_rows.map(&:repository_row_id)).to match_array [row.id, other_row.id]
    end

    it 'skips rows that are already assigned' do
      protocol.protocol_repository_rows.create!(repository_row: row)

      expect { action }.to change { protocol.protocol_repository_rows.count }.by(1)
    end

    it 'ignores rows the user cannot read' do
      foreign_row = create :repository_row
      post :create, params: { protocol_id: protocol.id, repository_row_ids: [foreign_row.id] }

      expect(response).to have_http_status(:ok)
      expect(protocol.protocol_repository_rows.count).to eq 0
    end

    it 'returns 422 when saving fails' do
      allow_any_instance_of(ProtocolRepositoryRow).to receive(:valid?).and_return(false)
      allow_any_instance_of(ActiveRecord::Associations::CollectionProxy).to receive(:create!)
        .and_raise(ActiveRecord::RecordInvalid.new(protocol))

      action

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json['errors']).to be_present
    end

    it 'returns forbidden without manage permissions' do
      allow(controller).to receive(:can_manage_protocol_draft_in_repository?).and_return(false)

      expect { action }.not_to(change { ProtocolRepositoryRow.count })
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST batch_destroy' do
    let!(:assigned) { protocol.protocol_repository_rows.create!(repository_row: row) }
    let!(:assigned_other) { protocol.protocol_repository_rows.create!(repository_row: other_row) }

    it 'unassigns the selected rows and logs activities' do
      expect do
        post :batch_destroy, params: { protocol_id: protocol.id, row_ids: [assigned.id] }
      end.to change { Activity.where(type_of: :protocol_repository_item_removed).count }.by(1)

      expect(response).to have_http_status(:no_content)
      expect(protocol.protocol_repository_rows.reload).to eq [assigned_other]
    end

    it 'returns 422 when removing fails' do
      allow_any_instance_of(ProtocolRepositoryRow).to receive(:destroy!).and_raise(StandardError, 'boom')
      post :batch_destroy, params: { protocol_id: protocol.id, row_ids: [assigned.id] }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(protocol.protocol_repository_rows.count).to eq 2
    end

    it 'returns forbidden without manage permissions' do
      allow(controller).to receive(:can_manage_protocol_draft_in_repository?).and_return(false)
      post :batch_destroy, params: { protocol_id: protocol.id, row_ids: [assigned.id] }

      expect(response).to have_http_status(:forbidden)
      expect(protocol.protocol_repository_rows.count).to eq 2
    end
  end

  describe 'GET repositories' do
    it 'returns readable repositories matching the query' do
      create :repository, team: team, created_by: user, name: 'Another'

      get :repositories, params: { protocol_id: protocol.id, query: 'Inventory' }

      expect(response).to have_http_status(:ok)
      expect(json['data']).to eq [[repository.id, repository.name_with_label]]
      expect(json['paginated']).to be true
      expect(json['next_page']).to be_nil
    end

    it 'returns forbidden without read permissions' do
      allow(controller).to receive(:can_read_protocol_in_repository?).and_return(false)
      get :repositories, params: { protocol_id: protocol.id }

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET repository_rows' do
    it 'returns rows of the selected repository that are not yet assigned' do
      protocol.protocol_repository_rows.create!(repository_row: row)

      get :repository_rows, params: { protocol_id: protocol.id, selected_repository_id: repository.id }

      expect(response).to have_http_status(:ok)
      expect(json['data']).to eq [[other_row.id, other_row.name_with_label]]
      expect(json['paginated']).to be true
    end

    it 'filters rows by the query' do
      get :repository_rows, params: { protocol_id: protocol.id, selected_repository_id: repository.id, query: 'Row two' }

      expect(json['data'].map(&:first)).to eq [other_row.id]
    end

    it 'raises RecordNotFound for an unreadable repository' do
      foreign = create :repository

      expect do
        get :repository_rows, params: { protocol_id: protocol.id, selected_repository_id: foreign.id }
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'POST actions_toolbar' do
    let!(:assigned) { protocol.protocol_repository_rows.create!(repository_row: row) }
    let(:items) { [{ id: assigned.id }].to_json }

    it 'offers the unassign action to managers' do
      post :actions_toolbar, params: { protocol_id: protocol.id, items: items }

      expect(response).to have_http_status(:ok)
      expect(json['actions'].map { |a| a['name'] }).to eq ['delete']
    end

    it 'returns no actions without selected rows' do
      post :actions_toolbar, params: { protocol_id: protocol.id, items: [].to_json }

      expect(json['actions']).to eq []
    end

    it 'returns no actions for users who cannot manage the draft' do
      without_partial_double_verification do
        allow_any_instance_of(Toolbars::ProtocolRepositoryRowsService)
          .to receive(:can_manage_protocol_draft_in_repository?).and_return(false)
      end
      post :actions_toolbar, params: { protocol_id: protocol.id, items: items }

      expect(json['actions']).to eq []
    end

    it 'returns forbidden without read permissions' do
      allow(controller).to receive(:can_read_protocol_in_repository?).and_return(false)
      post :actions_toolbar, params: { protocol_id: protocol.id, items: items }

      expect(response).to have_http_status(:forbidden)
    end
  end
end
