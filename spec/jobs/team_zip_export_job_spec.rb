# frozen_string_literal: true

require 'rails_helper'
require 'zip'

describe TeamZipExportJob, type: :job do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let!(:owner_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.owner')) }
  let!(:team_assignment) { create_user_assignment(team, owner_role, user) }
  let(:project) do
    create :project, team: team, created_by: user, name: 'Proj A', default_public_user_role_id: owner_role.id
  end
  let!(:project_assignment) { create_user_assignment(project, owner_role, user) }
  let(:archived_project) do
    create :project, team: team, created_by: user, name: 'Proj Arch', archived: true,
                     default_public_user_role_id: owner_role.id
  end
  let(:experiment) { create :experiment, project: project, created_by: user, name: 'Exp A' }
  let(:archived_experiment) { create :experiment, project: project, created_by: user, name: 'Exp Arch' }
  let(:my_module) do
    create :my_module, experiment: experiment, created_by: user, name: 'Mod A',
                       my_module_status: MyModuleStatus.first
  end
  let(:archived_module) do
    create :my_module, experiment: experiment, created_by: user, name: 'Mod Arch',
                       my_module_status: MyModuleStatus.first
  end
  let(:step) { create :step, protocol: my_module.protocol, user: user }
  let(:params) { { team_id: team.id, project_ids: [project.id, archived_project.id] } }

  before do
    user.update!(current_team_id: team.id)
    ZipExport.skip_callback(:create, :after, :self_destruct)
    allow_any_instance_of(Project).to receive(:generate_teams_export_report_html).and_return('<html>report</html>')
  end

  after do
    ZipExport.set_callback(:create, :after, :self_destruct)
    Dir.chdir(Rails.root)
  end

  def zip_entries
    path = ActiveStorage::Blob.service.public_send(:path_for, ZipExport.last.zip_file.key)
    Zip::File.open(path) { |zip| zip.entries.map(&:name) }
  end

  def run_job
    described_class.perform_now(user_id: user.id, params: params)
  end

  describe '#perform' do
    it 'exports projects, experiments and modules into a zip and notifies the user' do
      my_module
      archived_project
      archived_experiment.update_columns(archived: true)
      archived_module.update_columns(archived: true)

      expect { run_job }.to change(ZipExport, :count).by(1)
                        .and change(Notification, :count).by(1)

      entries = zip_entries
      team_dir = team.name.parameterize == team.name ? team.name : entries.first.split('/').first
      expect(entries).to include(a_string_matching(%r{Proj A \(1\)/Proj A \(1\) Report\.html}))
      expect(entries).to include(a_string_matching(%r{Archived projects/Proj Arch \(1\)}))
      expect(entries).to include(a_string_matching(%r{Exp A \(1\)/\(1\) Mod A/Protocol attachments}))
      expect(entries).to include(a_string_matching(%r{Archived experiments/Exp Arch \(1\)}))
      expect(entries).to include(a_string_matching(%r{Archived module/\(1\) Mod Arch|Archived module/\(\d\) Mod Arch}))
      expect(team_dir).to be_present
    end

    it 'exports step and result assets and tables' do
      create :step_asset, step: step
      create :step_table, step: step, table: create(:table, name: 'Step tbl')
      active_result = create :result, my_module: my_module, user: user
      archived_result = create :result, my_module: my_module, user: user, archived: true
      create :result_asset, result: active_result
      create :result_asset, result: archived_result
      create :result_table, result: active_result, table: create(:table, name: 'Res tbl')
      create :result_table, result: archived_result, table: create(:table, name: 'Arch tbl')
      params[:project_ids] = [project.id]

      run_job

      entries = zip_entries
      expect(entries).to include(a_string_matching(%r{Protocol attachments/test_1_Step\d+\.jpg}))
      expect(entries).to include(a_string_matching(%r{Protocol attachments/Step tbl\w*_0_Step\d+\.csv}))
      expect(entries).to include(a_string_matching(%r{Result attachments/test_1\.jpg}))
      expect(entries).to include(a_string_matching(%r{Result attachments/Archived attachments/test_1\.jpg}))
      expect(entries).to include(a_string_matching(%r{Result attachments/Res tbl\w*\.csv}))
      expect(entries).to include(a_string_matching(%r{Result attachments/Archived attachments/Arch tbl\w*\.csv}))
    end

    it 'skips assets whose file is missing in storage' do
      step_asset = create :step_asset, step: step
      step_asset.asset.file.blob.update_columns(key: 'missing-key')
      params[:project_ids] = [project.id]

      expect { run_job }.not_to raise_error
      expect(zip_entries).not_to include(a_string_matching(/test_1_Step/))
    end

    it 'exports done analytical reports of experiments and modules' do
      done = AnalyticalReport.new(reference: experiment, name: 'Exp rep', generating_status: :done, created_by: user)
      done.report.attach(io: StringIO.new('exp report'), filename: 'exp.pdf')
      done.save!
      mod_done = AnalyticalReport.new(reference: my_module, name: 'Mod rep', generating_status: :done,
                                      created_by: user)
      mod_done.report.attach(io: StringIO.new('mod report'), filename: 'mod.pdf')
      mod_done.save!
      pending = AnalyticalReport.new(reference: experiment, name: 'Pending', generating_status: :in_progress,
                                     created_by: user)
      pending.report.attach(io: StringIO.new('x'), filename: 'p.pdf')
      pending.save!
      params[:project_ids] = [project.id]

      run_job

      entries = zip_entries
      expect(entries).to include(a_string_matching(%r{Exp A \(1\)/Analytical reports/Exp rep_1\.pdf}))
      expect(entries).to include(a_string_matching(%r{\(1\) Mod A/Analytical reports/Mod rep_1\.pdf}))
      expect(entries).not_to include(a_string_matching(/Pending/))
    end

    it 'exports inventories assigned to the project as csv with attachments' do
      repository = create :repository, team: team, created_by: user, name: 'Inv'
      column = create :repository_column, repository: repository, created_by: user,
                                          name: 'Files', data_type: 'RepositoryAssetValue'
      row = create :repository_row, repository: repository, created_by: user, last_modified_by: user, name: 'Row 1'
      asset = create :asset, team: team
      create :repository_asset_value, asset: asset,
                                      repository_cell_attributes: { repository_row: row, repository_column: column }
      create :mm_repository_row, repository_row: row, my_module: my_module, assigned_by: user
      params[:project_ids] = [project.id]

      run_job

      entries = zip_entries
      csv = entries.find { |e| e =~ %r{Inventories/Inv \(0\)\.csv} }
      expect(csv).to be_present
      expect(entries).to include(a_string_matching(%r{Inventories/Inv \(0\) attachments/test_0\.jpg}))
    end

    it 'ignores projects that are not part of the requested ids' do
      project
      archived_project
      params[:project_ids] = [project.id]

      run_job

      expect(zip_entries).not_to include(a_string_matching(/Proj Arch/))
    end

    it 'restores the working directory after the export' do
      my_module
      run_job

      expect(Dir.pwd).to eq Rails.root.to_s
    end
  end

  describe '#failed_notification_title' do
    it 'uses the project item title' do
      job = described_class.new
      expect(job.send(:failed_notification_title)).to eq(
        I18n.t('activejob.failure_notifiable_job.item_notification_title',
               item: I18n.t('activejob.failure_notifiable_job.items.project'))
      )
    end
  end
end
