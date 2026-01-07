require 'rails_helper'

describe ResultElements::TextsController, type: :controller do
  login_user

  let!(:user) { subject.current_user }
  let!(:team) { create :team, created_by: user }
  let!(:protocol) { create :protocol, :in_repository_draft, added_by: user, team: team }
  let!(:result_template) { create :result_template, protocol: protocol, user: user }
  let!(:result_text) { create :result_text, result: result_template  }
  let!(:result_orderable_element) { create :result_orderable_element, result: result_template, orderable: result_text, position: 3}

  describe 'POST create' do
    it 'creates a new result element text' do
      expect {
        post :create, params: { result_id: result_template.id }
      }.to change(ResultText, :count).by(1)

      expect(response).to have_http_status(:success)
    end
  end

  describe 'PUT update' do
    it 'updates an existing result element text' do
      put :update, params: { result_id: result_template.id,
                             id: result_text.id,
                             text_component: { text: 'Updated Text', name: 'Updated Name' } }

      expect(response).to have_http_status(:success)
      result_text.reload
      expect(result_text.text).to eq('Updated Text')
      expect(result_text.name).to eq('Updated Name')
    end
  end

  describe 'POST move' do
    let!(:target_result) { create :result_template, protocol: protocol, user: user }
    it 'moves an existing result element text to another result' do
      post :move, params: { result_id: result_template.id,
                            id: result_text.id,
                            target_id: target_result.id }

      expect(response).to have_http_status(:success)
      result_text.reload
      expect(result_text.result).to eq(target_result)
    end
  end

  describe 'POST duplicate' do
    it 'duplicates an existing result element text' do
      expect {
        post :duplicate, params: { result_id: result_template.id,
                                  id: result_text.id }
      }.to change(ResultText, :count).by(1)
      expect(response).to have_http_status(:success)
    end
  end

  describe 'DELETE destroy' do
    it 'deletes an existing result element text' do
      expect {
        delete :destroy, params: { result_id: result_template.id,
                                   id: result_text.id }
      }.to change(ResultText, :count).by(-1)

      expect(response).to have_http_status(:success)
    end
  end

end
