require 'rails_helper'

describe ResultElements::TablesController, type: :controller do
  login_user

  let!(:user) { subject.current_user }
  let!(:team) { create :team, created_by: user }
  let!(:protocol) { create :protocol, :in_repository_draft, added_by: user, team: team }
  let!(:result_template) { create :result_template, protocol: protocol, user: user }
  let!(:result_table) { create :result_table, result: result_template  }
  let!(:result_orderable_element) { create :result_orderable_element, result: result_template, orderable: result_table, position: 3}

  describe 'POST create' do
    it 'creates a new result element table' do
      expect {
        post :create, params: { result_id: result_template.id, tableDimensions: [4, 4] }
      }.to change(ResultTable, :count).by(1)

      expect(response).to have_http_status(:success)
    end
  end

  describe 'PUT update' do
    it 'updates an existing result element table' do
      put :update, params: { result_id: result_template.id,
                             id: result_table.id,
                             name: 'Updated Name' }

      expect(response).to have_http_status(:success)
      result_table.reload
      expect(result_table.table.name).to eq('Updated Name')
    end
  end

  describe 'POST move' do
    let!(:target_result) { create :result_template, protocol: protocol, user: user }
    it 'moves an existing result element table to another result' do
      post :move, params: { result_id: result_template.id,
                            id: result_table.id,
                            target_id: target_result.id }

      expect(response).to have_http_status(:success)
      result_table.reload
      expect(result_table.result).to eq(target_result)
    end
  end

  describe 'POST duplicate' do
    it 'duplicates an existing result element table' do
      expect {
        post :duplicate, params: { result_id: result_template.id,
                                  id: result_table.id }
      }.to change(ResultTable, :count).by(1)
      expect(response).to have_http_status(:success)
    end
  end

  describe 'DELETE destroy' do
    it 'deletes an existing result element text' do
      expect {
        delete :destroy, params: { result_id: result_template.id,
                                   id: result_table.id }
      }.to change(ResultTable, :count).by(-1)

      expect(response).to have_http_status(:success)
    end
  end

end
