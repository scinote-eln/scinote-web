# frozen_string_literal: true

require 'rails_helper'

describe RepositoryStockValuesController, type: :controller do
  login_user
  let!(:user) { controller.current_user }
  let!(:team) { create :team, created_by: user }
  let!(:user_team) { create :user_team, :admin, team: team, user: user }
  let!(:repository) { create :repository, team: team, created_by: user}
  let(:repository_column) do
    create :repository_column, :stock_type, created_by: user, repository: repository
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

  describe 'create' do
    let(:params) do {
      repository_stock_value: {
        amount: 10,
        unit_item_id: repository_stock_unit_item.id,
        comment: 'test',
        low_stock_threshold: ''
      }, 
      operator: 'set',
      change_amount: 10,
      repository_id: repository.id,
      id: repository_row.id
    }
    end

    let(:action) { post :create_or_update, params: params, format: :json }
    it 'adds activity in DB' do
      expect { action }.to change(RepositoryStockValue, :count).by(1)
    end
  end
end
