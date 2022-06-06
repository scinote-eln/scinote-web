# frozen_string_literal: true

require 'rails_helper'

describe RepositoryStockValuesController, type: :controller do
  before :all do
    ApplicationSettings.instance.update(
      values: ApplicationSettings.instance.values.merge({"stock_management_enabled" => true})
    )
  end

  login_user
  let!(:user) { controller.current_user }
  let!(:team) { create :team, created_by: user }
  let!(:repository) { create :repository, team: team, created_by: user }
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

  describe 'create' do
    let(:params) do {
      repository_stock_value: {
        amount: 10,
        unit_item_id: repository_stock_unit_item.id,
        comment: 'test',
        low_stock_threshold: ''
      },
      operator: 'set',
      change_amount: 0,
      repository_id: repository.id,
      id: repository_row.id
    }
    end

    let(:action) { post :create_or_update, params: params, format: :json }
    let(:action1) { post :create_or_update, params: params, format: :json }

    it 'Create stock value' do
      expect { action }.to change(RepositoryLedgerRecord, :count).by(1)
    end

    it 'Ledger immutability' do
      action
      expect { action1 }
        .to (change(RepositoryLedgerRecord, :count).by(1)
              .and(change(RepositoryStockValue, :count).by(0)))
    end
  end
end
