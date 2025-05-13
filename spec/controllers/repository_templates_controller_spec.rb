# frozen_string_literal: true

require 'rails_helper'

describe RepositoryTemplatesController, type: :controller do
  login_user

  let!(:user) { controller.current_user }
  let!(:team) { create :team, created_by: user }

  describe 'index' do

    let(:action) { get :index, format: :json }

    it 'correct JSON format' do
      action

      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'application/json'
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data'].count).to eq(4)
      
    end
  end

  describe 'list_repository_columns' do
    let(:repository_template) { team.repository_templates.last }
    let(:action) { get :list_repository_columns, params: { id: repository_template } ,format: :json }
    let(:action_invalid) { get :list_repository_columns, params: { id: -1 } ,format: :json }

    it 'correct JSON format' do
      action

      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'application/json'

      parsed_response = JSON.parse(response.body)
      expect(parsed_response['name']).to eq(repository_template.name)
      expect(parsed_response['columns'].count).to eq(repository_template.column_definitions.count)
    end

    it 'invalid id' do
      action_invalid

      expect(response).to have_http_status(:not_found)
    
    end
  end
end
