# frozen_string_literal: true

require 'rails_helper'
require 'zip'

describe RepositoryStockZipExportJob, type: :job do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let!(:owner_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.owner')) }
  let!(:team_assignment) { create_user_assignment(team, owner_role, user) }
  let(:repository) { create :repository, team: team, created_by: user }
  
  before do
    2.times do |index|
      repository_row = create(
        :repository_row, 
        name: "row #{index}",
        repository: repository,
        created_by: user,
        last_modified_by: user)
      repository_row.repository_stock_value = build(:repository_stock_value)
      repository_stock_unit_item =
        create :repository_stock_unit_item,
          repository_column: repository_row.repository_stock_value.repository_cell.repository_column
      repository_row.repository_stock_value.repository_cell.repository_column.reload
      repository_row.save
      [100, 1500].each do |amount|
        repository_row.repository_stock_value.update_data!(
          { amount: amount, low_stock_threshold: '', unit_item_id: repository_stock_unit_item.id }, user
        )
      end
    end

    ZipExport.skip_callback(:create, :after, :self_destruct)
  end

  after do
    ZipExport.set_callback(:create, :after, :self_destruct)
  end

  describe '#generate_zip/2' do
    let(:action) do
      described_class.perform_now(user_id: user.id, params: { repository_row_ids: RepositoryRow.pluck(:id) })
    end

    it 'generates a new zip export object' do
      action

      expect(ZipExport.count).to eq 1
    end

    it 'generates a zip with csv file with exported rows' do
      action

      csv_zip_file = ZipExport.last.zip_file
      file_path = ActiveStorage::Blob.service.public_send(:path_for, csv_zip_file.key)
      parsed_csv_content = Zip::File.open(file_path) do |zip_file|
        csv_file = zip_file.glob('*.csv').last
        csv_content = csv_file.get_input_stream.read
        CSV.parse(csv_content, headers: true)
      end

      expect(
        parsed_csv_content.to_a[0]
      ).to eq(RepositoryStockLedgerZipExport::COLUMNS.map do |col|
        I18n.t("repository_stock_values.stock_export.headers.#{col}")
      end)
      expect(parsed_csv_content.length).to eq RepositoryLedgerRecord.count
    end
  end
end
