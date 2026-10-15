# frozen_string_literal: true

require 'rails_helper'

describe UserDataDeletion do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let!(:owner_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.owner')) }
  let(:project) { create :project, team: team, created_by: user, default_public_user_role_id: owner_role.id }
  let(:experiment) { create :experiment, project: project, created_by: user }
  let(:my_module) do
    create :my_module, experiment: experiment, created_by: user, my_module_status: MyModuleStatus.first
  end

  around do |example|
    original_logger = ActiveRecord::Base.logger
    example.run
    ActiveRecord::Base.logger = original_logger
  end

  describe '.delete_team_data' do
    it 'removes an empty team and detaches users from it' do
      user.update!(current_team_id: team.id)
      described_class.delete_team_data(team)

      expect(Team.exists?(team.id)).to be false
      expect(user.reload.current_team_id).to be_nil
      expect(UserAssignment.where(assignable: team)).to be_empty
    end

    it 'purges tiny mce assets' do
      asset = create :tiny_mce_asset, team: team
      blob_id = asset.image.blob.id

      described_class.delete_team_data(team)

      expect(TinyMceAsset.exists?(asset.id)).to be false
      expect(ActiveStorage::Blob.exists?(blob_id)).to be false
    end

    it 'deletes repositories together with their attachments' do
      repository = create :repository, team: team, created_by: user
      row = create :repository_row, repository: repository, created_by: user, last_modified_by: user
      cell = create :repository_cell, :asset_value, repository_row: row
      cell.value.asset.file.attach(io: File.open(Rails.root.join('spec/fixtures/files/test.jpg')),
                                   filename: 'test.jpg')
      asset_id = cell.value.asset.id

      described_class.delete_team_data(team)

      expect(Repository.exists?(repository.id)).to be false
      expect(RepositoryRow.exists?(row.id)).to be false
      expect(Asset.exists?(asset_id)).to be false
    end

    it 'deletes the project hierarchy with its dependent records' do
      create :project_comment, project: project, user: user
      create :report, project: project, team: team, user: user
      result = create :result, my_module: my_module, user: user
      result_asset = create :result_asset, result: result
      create :task_comment, my_module: my_module, user: user
      Activity.create!(type_of: :create_project, owner: user, team: team, subject: project, project: project,
                       message: 'project created')
      experiment.workflowimg.attach(io: StringIO.new('img'), filename: 'flow.png')
      protocol_id = my_module.protocol.id
      step = create :step, protocol: my_module.protocol, user: user
      create :step_asset, step: step
      create :step_table, step: step
      create :step_text, step: step
      create :checklist, step: step
      create :step_comment, step: step, user: user
      step_id = step.id
      other_module = create :my_module, experiment: experiment, created_by: user,
                                        my_module_status: MyModuleStatus.first
      create :connection, input_id: my_module.id, output_id: other_module.id

      described_class.delete_team_data(team)

      expect(Project.exists?(project.id)).to be false
      expect(Experiment.exists?(experiment.id)).to be false
      expect(MyModule.where(id: [my_module.id, other_module.id])).to be_empty
      expect(Protocol.exists?(protocol_id)).to be false
      expect(Step.exists?(step_id)).to be false
      expect(Asset.exists?(result_asset.asset.id)).to be false
      expect(Report.where(project_id: project.id)).to be_empty
      expect(Activity.where(project_id: project.id)).to be_empty
      expect(Connection.where(input_id: my_module.id)).to be_empty
      expect(Team.exists?(team.id)).to be false
    end

    it 'deletes repository protocols, keywords, tags and reports of the team' do
      protocol = create :protocol, :in_repository_published_original, team: team, added_by: user
      step = create :step, protocol: protocol, user: user
      keyword = create :protocol_keyword, team: team
      tag = create :tag, team: team
      report = create :report, team: team, user: user, project: project

      described_class.delete_team_data(team)

      expect(Protocol.exists?(protocol.id)).to be false
      expect(Step.exists?(step.id)).to be false
      expect(ProtocolKeyword.exists?(keyword.id)).to be false
      expect(Tag.exists?(tag.id)).to be false
      expect(Report.exists?(report.id)).to be false
    end

    it 'does not touch other teams' do
      other_team = create :team
      other_project = create :project, team: other_team
      described_class.delete_team_data(team)
      expect(Team.exists?(other_team.id)).to be true
      expect(Project.exists?(other_project.id)).to be true
    end

    it 'rolls back everything when the deletion fails' do
      project
      allow_any_instance_of(Team).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed)

      expect { described_class.delete_team_data(team) }.to raise_error(ActiveRecord::RecordNotDestroyed)
      expect(Project.exists?(project.id)).to be true
      expect(Team.exists?(team.id)).to be true
    end
  end

  describe '.destroy_notifications' do
    it 'removes all notifications of the user' do
      other = create :user
      create_list :notification, 3, type: 'GeneralNotification', recipient: user
      kept = create :notification, type: 'GeneralNotification', recipient: other

      described_class.destroy_notifications(user)

      expect(user.notifications.reload).to be_empty
      expect(other.notifications.reload).to contain_exactly(kept)
    end
  end
end
