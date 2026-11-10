# frozen_string_literal: true

require 'rails_helper'
require 'zip'

describe RepositoriesExportJob, type: :job do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user, name: 'Team X' }
  let!(:owner_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.owner')) }
  let!(:team_assignment) { create_user_assignment(team, owner_role, user) }
  let(:repository) { create :repository, team: team, created_by: user, name: 'Inv One' }
  let(:other_repository) { create :repository, team: team, created_by: user, name: 'Inv Two' }
  let!(:text_column) do
    create :repository_column, repository: repository, created_by: user, name: 'Notes',
                               data_type: 'RepositoryTextValue'
  end

  before do
    user.update!(current_team_id: team.id)
    ZipExport.skip_callback(:create, :after, :self_destruct)
    row = create :repository_row, name: 'Row A', repository: repository, created_by: user, last_modified_by: user
    create :repository_text_value, data: 'note text',
                                   repository_cell_attributes: { repository_row: row, repository_column: text_column }
  end

  after { ZipExport.set_callback(:create, :after, :self_destruct) }

  def zip_contents
    path = ActiveStorage::Blob.service.public_send(:path_for, ZipExport.last.zip_file.key)
    Zip::File.open(path) { |zip| zip.entries.to_h { |e| [e.name, e.directory? ? nil : e.get_input_stream.read] } }
  end

  it 'exports each readable repository as a csv with an attachments directory and notifies the user' do
    other_repository

    expect do
      described_class.perform_now(:csv, [repository.id, other_repository.id], user_id: user.id, team_id: team.id)
    end.to change(ZipExport, :count).by(1).and change(Notification, :count).by(1)

    entries = zip_contents
    expect(entries.keys).to include('Team X/Inv One (0).csv', 'Team X/Inv Two (1).csv')
    expect(entries.keys.grep(/attachments/).length).to eq 2
    csv = CSV.parse(entries['Team X/Inv One (0).csv'], headers: true)
    expect(csv.map { |r| r['Name'] }).to eq ['Row A']
    expect(csv.map { |r| r['Notes'] }).to eq ['note text']
    expect(Notification.last.to_notification.message).to include(ZipExport.last.zip_file_name)
  end

  it 'ignores repositories that were not requested' do
    other_repository

    described_class.perform_now(:csv, [repository.id], user_id: user.id, team_id: team.id)

    expect(zip_contents.keys.grep(/Inv Two/)).to be_empty
  end

  it 'saves attachments next to the export and links them from the csv' do
    row = repository.repository_rows.first
    cell = create :repository_cell, :asset_value, repository_row: row
    cell.value.asset.file.attach(io: File.open(Rails.root.join('spec/fixtures/files/test.jpg')),
                                 filename: 'test.jpg')
    asset_column = cell.repository_column
    asset_column.update!(name: 'Files')

    described_class.perform_now(:csv, [repository.id], user_id: user.id, team_id: team.id)

    entries = zip_contents
    expect(entries.keys).to include('Team X/Inv One (0) attachments/test_0.jpg')
    csv = CSV.parse(entries['Team X/Inv One (0).csv'], headers: true)
    expect(csv.first['Files']).to include('Inv One (0) attachments/test_0.jpg')
  end

  it 'exports xlsx files' do
    described_class.perform_now(:xlsx, [repository.id], user_id: user.id, team_id: team.id)

    expect(zip_contents.keys).to include('Team X/Inv One (0).xlsx')
  end

  it 'notifies the user with the repository title when the export fails and re-raises' do
    allow_any_instance_of(RepositoryExportService).to receive(:export!).and_raise(StandardError, 'bad export')
    job = described_class.new(:csv, [repository.id], user_id: user.id, team_id: team.id)
    job.enqueued_at = Time.current

    expect { job.perform_now }.to raise_error(StandardError, 'bad export')
    expect(ZipExport.count).to eq 0
    expect(Notification.last.to_notification.title).to eq(
      I18n.t('activejob.failure_notifiable_job.item_notification_title',
             item: I18n.t('activejob.failure_notifiable_job.items.repository'))
    )
  end
end
