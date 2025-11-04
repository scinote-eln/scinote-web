# frozen_string_literal: true

require 'rails_helper'

describe TagsController, type: :controller do
  login_user

  include_context 'reference_project_structure', {
    tag: true
  }

  describe 'POST create' do
    let(:action) { post :create, params: params, format: :json }
    let(:params) do
      {
        team_id: team.id,
        tag: { team_id: team.id,
               name: 'name',
               color: '#123456' }
      }
    end

    it 'creates new tag' do
      expect { action }
        .to(change { Tag.count }.by(1))
    end

    it 'returns a success response' do
      action
      expect(response).to have_http_status(:success)
    end

    it 'logs the activity' do
      expect_any_instance_of(TagsController).to receive(:log_activity).with(:tag_created, instance_of(Tag))
      action
    end
  end

  describe 'PUT update' do
    let(:action) do
      put :update, params: {
        id: tag.id,
        team_id: team.id,
        tag: { name: 'Name2' }
      }, format: :json
    end

    it 'updates tag' do
      expect { action }
        .to(change { tag.reload.name }.from(tag.name).to('Name2'))
    end

    it 'returns a success response' do
      action
      expect(response).to have_http_status(:success)
    end

    it 'logs the activity' do
      expect_any_instance_of(TagsController).to receive(:log_activity).with(:tag_edited, tag)
      action
    end
  end

  describe 'DELETE destroy_tags' do
    let(:action) do
      delete :destroy_tags, params: {
        tag_ids: [tag.id],
        team_id: team.id
      }, format: :json
    end

    it 'deletes tag' do
      tag # create tag
      expect { action }
        .to(change { Tag.count }.by(-1))
    end

    it 'returns a success response' do
      action
      expect(response).to have_http_status(:success)
    end

    it 'logs the activity' do
      expect_any_instance_of(TagsController).to receive(:log_activity).with(:tag_deleted, tag)
      action
    end
  end

  describe 'POST merge' do
    let!(:tag) { create :tag, team: team }
    let!(:tag2) { create :tag, team: team }
    let!(:tagging) { create :tagging, tag: tag, taggable: my_module }
    let!(:tagging2) { create :tagging, tag: tag2, taggable: my_module }
    let(:action) do
      post :merge, params: {
        id: tag.id,
        team_id: team.id,
        merge_ids: [tag2.id]
      }, format: :json
    end

    before do
    end

    it 'removes merged tags' do
      expect { action }
        .to(change { Tag.count }.by(-1))
    end

    it 'reassigns taggings to the main tag' do
      expect { action }
        .to(change { Tagging.where(tag: tag2).count }.by(-1))
    end

    it 'returns a success response' do
      action
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET colors' do
    let(:action) { get :colors, format: :json }

    it 'returns a success response' do
      action
      expect(response).to have_http_status(:success)
    end

    it 'returns the colors' do
      action
      expect(JSON.parse(response.body)).to include('colors')
    end
  end
end
