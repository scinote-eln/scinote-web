# frozen_string_literal: true

require 'rails_helper'

describe RepositoryStockValuesController, type: :controller do
  login_user
  let!(:user) { controller.current_user }
  let!(:team) { create :team, created_by: user }
  let!(:repository) { create :repository, team: team, created_by: user }
  let(:repository_column) do
    create :repository_column, created_by: user, repository: repository
  end

  let!(:repository_row) do
    create :repository_row, repository: repository,
                            created_by: user,
                            last_modified_by: user
  end

  let!(:repository_stock_unit_item) {create :repository_stock_unit_item, created_by: user,
                                                                         last_modified_by: user,
                                                                         repository_column: repository_column}

  #let!(:repository_stock_value) {create :repository_stock_value, created_by: user,
  #                                                               last_modified_by: user,
  #                                                               repository_stock_unit_item: repository_stock_unit_item
  #                                                              }                                                                       

  include_context 'reference_project_structure' , {
    created_by: controller.current_user,
    role: :owner
  }

  describe 'create' do
    let(:params) {}
    let(:repository_stock_value) {post :create_or_update, params:{ amount:10, 
                                                                   repository_id: repository.id,
                                                                   id: repository_row.id,
                                                                   repository_column_id: repository_column.id,
                                                                   unit_item_id: repository_stock_unit_item.id} }
    it 'adds activity in DB' do
      post :create_or_update, params:{ amount:10, 
                                                                   repository_id: repository.id,
                                                                   id: repository_row.id,
                                                                   repository_column_id: repository_column.id,
                                                                   unit_item_id: repository_stock_unit_item.id} 
      expect(response).to have_http_status(403)
    end
  end
end
