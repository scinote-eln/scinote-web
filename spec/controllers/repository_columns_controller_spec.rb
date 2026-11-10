# frozen_string_literal: true

require 'rails_helper'

describe RepositoryColumnsController, type: :controller do
  login_user

  let(:user) { subject.current_user }
  let(:team) { create :team, created_by: user }
  let(:repository) { create :repository, created_by: user, team: team }
  let(:repository_column) do
    create :repository_column, created_by: user, repository: repository
  end

  describe 'DELETE destroy' do
    let(:action) { delete :destroy, params: params, format: :json }
    let(:params) do
      { repository_id: repository.id, id: repository_column.id }
    end

    it 'calls create activity for deleting inventory items' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :delete_column_inventory)))

      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'extra coverage' do
    render_views

    let!(:viewer_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.viewer')) || create(:viewer_role) }
    let(:text_column) { create :repository_column, :text_type, created_by: user, repository: repository }

    def make_viewer
      UserAssignment.where(user: user, assignable: [team, repository]).update_all(user_role_id: viewer_role.id)
    end

    def json
      JSON.parse(response.body)
    end

    it 'index_new serializes the columns' do
      text_column
      get :index_new, params: { repository_id: repository.id }, format: :json
      expect(response).to have_http_status(:ok)
      expect(json['data'].size).to eq 1
    end

    it 'describe_all lists searchable columns plus updated_on/updated_by' do
      text_column
      get :describe_all, params: { repository_id: repository.id }, format: :json
      ids = json['response'].map { |c| c['id'] }
      expect(ids).to include(text_column.id, 'updated_on', 'updated_by')
    end

    it 'available_columns lists column ids' do
      text_column
      get :available_columns, params: { repository_id: repository.id }, format: :json
      expect(json['columns']).to eq [text_column.id]
    end

    it 'destroy removes the column' do
      text_column
      expect do
        delete :destroy, params: { repository_id: repository.id, id: text_column.id }, format: :json
      end.to change { repository.repository_columns.count }.by(-1)
      expect(json['id']).to eq text_column.id
    end

    # bug: error branch puts status: :unprocessable_entity in the JSON body, so HTTP stays 200 and the JS shows success
    # bug: delete_column_inventory activity is logged before destroy, so a failed destroy still records it
    it 'destroy reports an error when the column cannot be destroyed' do
      text_column
      allow_any_instance_of(RepositoryColumn).to receive(:destroy).and_return(false)
      expect do
        delete :destroy, params: { repository_id: repository.id, id: text_column.id }, format: :json
      end.to change { Activity.count }.by(1)
      expect(response).to have_http_status(:ok)
      expect(json['message']).to be_present
      expect(repository.repository_columns.count).to eq 1
    end

    it 'returns 404 for an unknown repository' do
      get :index_new, params: { repository_id: -1 }, format: :json
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 for an unknown column' do
      delete :destroy, params: { repository_id: repository.id, id: -1 }, format: :json
      expect(response).to have_http_status(:not_found)
    end

    context 'as a viewer' do
      before { make_viewer }

      it 'forbids destroy' do
        text_column
        expect do
          delete :destroy, params: { repository_id: repository.id, id: text_column.id }, format: :json
        end.not_to(change { RepositoryColumn.count })
        expect(response).to have_http_status(:forbidden)
      end

      it 'still allows reading columns' do
        get :index_new, params: { repository_id: repository.id }, format: :json
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
