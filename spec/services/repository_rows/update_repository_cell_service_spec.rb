# frozen_string_literal: true

require 'rails_helper'

describe RepositoryRows::UpdateRepositoryCellService do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:repository) { create :repository, team: team, created_by: user }
  let(:row) { create :repository_row, repository: repository }
  def service_call(params) 
    described_class.call(repository_row: row, user: user, params: params)
  end
  
  context 'Text type' do
    let(:column) { create :repository_column, :text_type, repository: repository }
    it 'creates new cell' do
      params = { repository_cell: { column_id: column.id, value: 'Test text' } }
      service = service_call(params)
      expect(service.record_updated).to be_truthy
      expect(row.repository_text_values.last.data).to match(/Test text/)
    end

    it 'fails to create new cell' do
      params = { repository_cell: { column_id: column.id } }
      service = service_call(params)
      expect(service.record_updated).to be_falsey
      expect(service.errors.any?).to be_truthy
    end

    it 'updates existing cell value' do
      RepositoryCell.create_with_value!(row, column, 'Test text', user)
      params = { repository_cell: { column_id: column.id, value: 'Another Text' } }
      service = service_call(params)
      expect(service.record_updated).to be_truthy
      expect(row.repository_text_values.last.data).to match(/Another Text/)
    end

    it 'delete existing cells' do
      RepositoryCell.create_with_value!(row, column, 'Test text', user)
      params = { repository_cell: { column_id: column.id, value: '' } }
      service = service_call(params)
      expect(service.record_updated).to be_truthy
      expect(row.repository_text_values.last).to be_nil
    end
  end
end
