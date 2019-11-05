# frozen_string_literal: true

require 'rails_helper'
require 'zip'

describe RepositoryZipExport, type: :background_job do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:user_team) { create :user_team, user: user, team: team }
  let(:repository) { create :repository, team: team, created_by: user }
  let!(:sample_group_column) do
    create :repository_column, repository: repository,
                               created_by: user,
                               name: 'Sample group',
                               data_type: 'RepositoryListValue'
  end
  let!(:repository_list_item) do
    create :repository_list_item, data: 'item one',
                                  repository: repository,
                                  repository_column: sample_group_column
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
        row_ids: @row_ids }
    end

    it 'generates a new zip export object' do
      ZipExport.skip_callback(:create, :after, :self_destruct)
      RepositoryZipExport.generate_zip(params, repository, user)
      expect(ZipExport.count).to eq 1
      ZipExport.set_callback(:create, :after, :self_destruct)
    end

    it 'generates a zip with csv file with exported rows' do
      ZipExport.skip_callback(:create, :after, :self_destruct)
      RepositoryZipExport.generate_zip(params, repository, user)
      csv_zip_file = ZipExport.first.zip_file
      file_path = ActiveStorage::Blob.service.public_send(:path_for, csv_zip_file.key)
      parsed_csv_content = Zip::File.open(file_path) do |zip_file|
        csv_file = zip_file.glob('*.csv').first
        csv_content = csv_file.get_input_stream.read
        CSV.parse(csv_content, headers: true)
      end
      index = 0

      parsed_csv_content.each do |row|
        row_hash = row.to_h
        expect(row_hash.fetch('Sample group')).to eq 'item one'
        expect(row_hash.fetch('Custom items')).to eq 'custum column value'
        expect(row_hash.fetch('Name')).to eq "row #{index}"
        index += 1
      end
      ZipExport.set_callback(:create, :after, :self_destruct)
    end
  end
end
