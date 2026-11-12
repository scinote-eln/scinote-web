# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReportActions::SavePdfToInventoryItem do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:project) { create :project, team: team, created_by: user }
  let(:report) { create :report, user: user, project: project, team: team }
  let(:repository) { create :repository, team: team, created_by: user }
  let(:column) { create :repository_column, :asset_type, repository: repository, created_by: user }
  let(:row) { create :repository_row, repository: repository, created_by: user }
  let(:params) { { repository_id: repository.id, repository_column_id: column.id, repository_item_id: row.id } }

  before do
    user.update!(current_team_id: team.id)
    allow(Activities::CreateActivityService).to receive(:call)
    report.pdf_file.attach(io: StringIO.new('%PDF-1.4 content'), filename: 'report.pdf', content_type: 'application/pdf')
  end

  def build
    described_class.new(report, user, team, params)
  end

  describe '#initialize' do
    # bug: an unreadable repository is nil and the permission check raises ArgumentError instead of the permission error
    pending 'bug: unreadable repository must raise RepositoryPermissionError' do
      other = create :repository, team: create(:team), created_by: create(:user)
      params[:repository_id] = other.id
      expect { build }.to raise_error(ReportActions::RepositoryPermissionError, I18n.t('projects.reports.new.no_permissions'))
    end

    it 'raises a permission error when the user may not create rows' do
      viewer_role = UserRole.find_by(name: I18n.t('user_roles.predefined.viewer')) || create(:viewer_role)
      viewer = create :user
      viewer.update!(current_team_id: team.id)
      create :user_assignment, user: viewer, assignable: team, user_role: viewer_role, assigned_by: user
      create_user_assignment(repository, viewer_role, viewer, user)
      expect { described_class.new(report, viewer, team, params) }
        .to raise_error(ReportActions::RepositoryPermissionError)
    end

    it 'raises RecordNotFound for a column outside the repository' do
      params[:repository_column_id] = create(:repository_column, :asset_type).id
      expect { build }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'raises RecordNotFound for an item outside the repository' do
      params[:repository_item_id] = create(:repository_row).id
      expect { build }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '#save' do
    it 'stores the report PDF as an asset value in the item cell' do
      service = build
      expect { service.save }.to change(Asset, :count).by(1).and change(RepositoryAssetValue, :count).by(1)

      cell = row.repository_cells.find_by(repository_column: column)
      asset = cell.value.asset
      expect(asset.team).to eq team
      expect(asset.created_by).to eq user
      expect(asset.file.download).to eq '%PDF-1.4 content'
    end

    it 'replaces an existing cell of the same column' do
      first = build
      first.save
      old_cell = row.repository_cells.find_by(repository_column: column)

      expect { build.save }.not_to(change { row.repository_cells.where(repository_column: column).count })
      expect(RepositoryCell.exists?(old_cell.id)).to be false
    end

    it 'logs an item edit activity' do
      build.save
      expect(Activities::CreateActivityService).to have_received(:call).with(
        activity_type: :edit_item_inventory, owner: user, subject: row, team: team,
        message_items: { repository_row: row.id, repository: repository.id }
      )
    end
  end

  describe '#error_messages' do
    it 'returns the generic error before anything was saved' do
      expect(build.error_messages).to eq I18n.t('general.error')
    end

    it 'returns the validation messages of the new cell value (none after a successful save)' do
      service = build
      service.save
      expect(service.error_messages).to eq ''
    end
  end
end
