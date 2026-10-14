# frozen_string_literal: true

require 'rails_helper'

describe LabelTemplatesController, type: :controller do
  login_user

  let!(:user) { controller.current_user }
  let!(:team) { create :team, :change_user_team, created_by: user }
  let!(:other_team) { create :team }
  let(:own_template) { team.label_templates.find_by(type: 'ZebraLabelTemplate', default: true) }
  let(:other_team_template) { other_team.label_templates.find_by(type: 'ZebraLabelTemplate', default: true) }

  before do
    allow(LabelTemplate).to receive(:enabled?).and_return(true)
  end

  describe 'GET show' do
    it 'returns the label template from a team the user has access to' do
      get :show, params: { id: own_template.id }, format: :json

      expect(response).to have_http_status(:success)
    end

    it 'denies access to a label template from a team the user is not a member of' do
      get :show, params: { id: other_team_template.id }, format: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'PUT update' do
    let(:params) { { id: other_team_template.id, label_template: { name: 'Hijacked template' } } }

    it 'denies updating a label template from a team the user is not a member of' do
      put :update, params: params, format: :json

      expect(response).to have_http_status(:forbidden)
      expect(other_team_template.reload.name).not_to eq('Hijacked template')
    end
  end

  describe 'POST set_default' do
    let(:non_default_template) { other_team.label_templates.find_by(type: 'ZebraLabelTemplate', default: false) }

    it 'denies setting default label template in a team the user is not a member of' do
      post :set_default, params: { id: non_default_template.id }, format: :json

      expect(response).to have_http_status(:forbidden)
      expect(non_default_template.reload.default).to be(false)
    end
  end
end
