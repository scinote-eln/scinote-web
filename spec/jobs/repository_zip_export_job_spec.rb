# frozen_string_literal: true

require 'rails_helper'
require 'zip'

describe RepositoryZipExportJob, type: :job do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let!(:owner_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.owner')) }
  let!(:team_assignment) { create_user_assignment(team, owner_role, user) }
  let(:repository) { create :repository, team: team, created_by: user }
  let!(:sample_group_column) do
    create :repository_column, repository: repository,
                               created_by: user,
                               name: 'Sample group',
                               data_type: 'RepositoryListValue'
  end
  let!(:repository_list_item) do
    create :repository_list_item, data: 'item one', repository_column: sample_group_column
  end
  let!(:custom_column) do
    create :repository_column, repository: repository,
                               created_by: user,
                               name: 'Custom items',
                               data_type: 'RepositoryTextValue'
  end

  before do
    @row_ids = []
    10.times do |index|
      row = create :repository_row, name: "row #{index}",
                                    repository: repository,
                                    created_by: user,
                                    last_modified_by: user
      create :repository_list_value, repository_list_item: repository_list_item,
                                     repository_cell_attributes: {
                                       repository_row: row,
                                       repository_column: sample_group_column
                                     }
      create :repository_text_value, data: 'custum column value',
                                     repository_cell_attributes: {
                                       repository_row: row,
                                       repository_column: custom_column
                                     }

      @row_ids << row.id.to_s
    end

    ZipExport.skip_callback(:create, :after, :self_destruct)
  end

  after do
    ZipExport.set_callback(:create, :after, :self_destruct)
  end

  describe '#generate_zip/2' do
    let(:params) do
      { header_ids: ['-1',
                     '-2',
                     sample_group_column.id.to_s,
                     custom_column.id.to_s,
                     '-3',
                     '-5',
                     '-4'],
        repository_id: repository.id,
        row_ids: @row_ids }
    end

    it 'generates a new zip export object' do
      described_class.perform_now(user_id: user.id, params: params)
      expect(ZipExport.count).to eq 1
    end

    it 'generates a zip with csv file with exported rows' do
      described_class.perform_now(user_id: user.id, params: params)
      csv_zip_file = ZipExport.first.zip_file
      file_path = ActiveStorage::Blob.service.public_send(:path_for, csv_zip_file.key)
      parsed_csv_content = Zip::File.open(file_path) do |zip_file|
        csv_file = zip_file.glob('*.csv').first
        csv_content = csv_file.get_input_stream.read
        CSV.parse(csv_content, headers: true)
      end

      expect(parsed_csv_content.size).to eq 10
      expect(parsed_csv_content.map { |row| row.to_h.fetch('Name') })
        .to match_array(10.times.map { |index| "row #{index}" })
      parsed_csv_content.each do |row|
        expect(row.to_h.fetch('Sample group')).to eq 'item one'
        expect(row.to_h.fetch('Custom items')).to eq 'custum column value'
      end
    end
  end
  describe 'exporting in a task context' do
    let(:project) { create :project, team: team, created_by: user }
    let(:experiment) { create :experiment, project: project, created_by: user }
    let(:my_module) { create :my_module, experiment: experiment, created_by: user }
    let(:assigned_row) { repository.repository_rows.order(:id).first }
    let(:base_params) do
      { header_ids: ['-4', custom_column.id.to_s], repository_id: repository.id, my_module_id: my_module.id }
    end

    def exported_csv(zip_export = ZipExport.last)
      file_path = ActiveStorage::Blob.service.public_send(:path_for, zip_export.zip_file.key)
      Zip::File.open(file_path) do |zip_file|
        CSV.parse(zip_file.glob('*.csv').first.get_input_stream.read, headers: true)
      end
    end

    it 'exports only the rows assigned to the task' do
      create :mm_repository_row, my_module: my_module, repository_row: assigned_row, assigned_by: user

      described_class.perform_now(user_id: user.id, params: base_params)

      names = exported_csv.map { |r| r['Name'] }
      expect(names).to eq [assigned_row.name]
    end

    it 'exports all rows of a repository snapshot of the task' do
      snapshot = create :repository_snapshot, original_repository: repository, my_module: my_module,
                                               team: team, created_by: user
      snapshot_row = create :repository_row, repository: snapshot, name: 'snap row', created_by: user,
                                             last_modified_by: user

      described_class.perform_now(user_id: user.id, params: base_params.merge(repository_id: snapshot.id))

      expect(exported_csv.map { |r| r['Name'] }).to eq [snapshot_row.name]
    end

    it 'joins stock consumption when the repository has stock management' do
      create :mm_repository_row, my_module: my_module, repository_row: assigned_row, assigned_by: user
      stock_column = create :repository_column, :stock_type, repository: repository, created_by: user
      unit_item = create :repository_stock_unit_item, repository_column: stock_column, created_by: user
      create :repository_stock_value, repository_stock_unit_item: unit_item, amount: 10,
                                      repository_cell_attributes: { repository_row: assigned_row,
                                                                    repository_column: stock_column }
      mm_row = MyModuleRepositoryRow.find_by!(my_module: my_module, repository_row: assigned_row)
      mm_row.update_columns(stock_consumption: 3, repository_stock_unit_item_id: unit_item.id)
      allow(RepositoryBase).to receive(:stock_management_enabled?).and_return(true)
      expect(repository.reload.has_stock_management?).to be true

      described_class.perform_now(user_id: user.id, params: base_params)

      csv = exported_csv
      expect(csv.map { |r| r['Name'] }).to eq [assigned_row.name]
      expect(csv.map { |r| r[I18n.t('repositories.table.row_consumption')] }).to eq ["3 #{unit_item.data}"]
    end
  end

  describe 'failure' do
    it 'notifies the user with the repository item title and re-raises' do
      job = described_class.new(user_id: user.id, params: { repository_id: -1, header_ids: [], row_ids: [] })
      job.enqueued_at = Time.current

      expect { job.perform_now }.to raise_error(ActiveRecord::RecordNotFound)

      expect(Notification.last.to_notification.title).to eq(
        I18n.t('activejob.failure_notifiable_job.item_notification_title',
               item: I18n.t('activejob.failure_notifiable_job.items.repository_item'))
      )
    end
  end
end
