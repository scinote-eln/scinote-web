# frozen_string_literal: true

require 'rails_helper'
require 'tmpdir'

describe 'data' do
  # The rake file is loaded once per process (a reload resets Ruby's line coverage of the file) and
  # every task is re-enabled before each example.
  rake_applications = {}
  load_rake_application = lambda do
    rake_applications[:data] ||= Rake::Application.new.tap do |application|
      previous = Rake.application
      Rake.application = application
      Rake::Task.define_task(:environment)
      load Rails.root.join('lib/tasks/data.rake').to_s
    ensure
      Rake.application = previous
    end
  end

  let(:rake) { load_rake_application.call }
  let(:log_io) { StringIO.new }
  let(:tmp_dir) { Dir.mktmpdir('data_rake_spec') }

  # The rake file replaces Rails.logger with a STDOUT logger at load time: capture and restore it.
  around do |example|
    original_logger = Rails.logger
    original_dir = Dir.pwd
    original_rake = Rake.application
    Rake.application = rake
    rake.tasks.each(&:reenable)
    example.run
  ensure
    Rake.application = original_rake
    Dir.chdir(original_dir)
    restore_importer_callbacks
    Rails.logger = original_logger
    FileUtils.remove_entry(tmp_dir) if tmp_dir && File.exist?(tmp_dir)
  end

  before { Rails.logger = Logger.new(log_io) }

  # TeamImporter skips these callbacks and only re-enables them on success.
  def restore_importer_callbacks
    {
      MyModule => [:create, :before, :create_blank_protocol],
      Activity => [:create, :before, :add_user]
    }.each do |klass, (event, kind, filter)|
      present = klass.send("_#{event}_callbacks").any? { |c| c.filter == filter && c.kind == kind }
      klass.set_callback(event, kind, filter) unless present
    end
    present = Activity._initialize_callbacks.any? { |c| c.filter == :init_default_values && c.kind == :after }
    Activity.set_callback(:initialize, :after, :init_default_values) unless present
  end

  # The exporter/importer ask for a serializable transaction, which Postgres refuses inside the
  # per-example test transaction. Run the real code without the isolation option.
  def without_transaction_isolation
    allow_any_instance_of(Team).to receive(:transaction).and_wrap_original do |original, **_options, &block|
      original.call(&block)
    end
  end

  def run_task(name, *args)
    rake[name].invoke(*args)
  end

  describe 'data:clean_temp_files' do
    let!(:old_file) { create(:temp_file).tap { |f| f.update_columns(created_at: 4.days.ago) } }
    let!(:fresh_file) { create(:temp_file) }

    it 'removes temp files older than 3 days and keeps fresh ones' do
      expect { run_task('data:clean_temp_files') }.to change(TempFile, :count).by(-1)
      expect(TempFile.exists?(old_file.id)).to be false
      expect(TempFile.exists?(fresh_file.id)).to be true
      expect(log_io.string).to include("Temporary file ##{old_file.id} removed")
    end

    it 'logs the error and keeps the file when destroying fails' do
      allow_any_instance_of(TempFile).to receive(:destroy!).and_raise(StandardError, 'boom')

      expect { run_task('data:clean_temp_files') }.not_to change(TempFile, :count)
      expect(log_io.string).to include("Failed to destroy temporary file #{old_file.id}: boom")
    end
  end

  describe 'data:clean_unconfirmed_users' do
    around do |example|
      confirm_within = Devise.confirm_within
      invite_for = Devise.invite_for
      Devise.confirm_within = 3.days
      Devise.invite_for = 7.days
      example.run
    ensure
      Devise.confirm_within = confirm_within
      Devise.invite_for = invite_for
    end

    def old_user(attrs = {})
      user = create(:user, attrs)
      user.update_columns(attrs.merge(created_at: 10.days.ago))
      user
    end

    it 'removes self-signed-up users whose confirmation expired, together with their own team' do
      stale = old_user(confirmed_at: nil, confirmation_token: 'tok-stale')
      team = create(:team, created_by: stale)
      recent = create(:user, confirmed_at: nil, confirmation_token: 'tok-recent')
      confirmed = create(:user)

      run_task('data:clean_unconfirmed_users')

      expect(User.exists?(stale.id)).to be false
      expect(Team.exists?(team.id)).to be false
      expect(User.exists?(recent.id)).to be true
      expect(User.exists?(confirmed.id)).to be true
      expect(log_io.string).to include("Unconfirmed user ##{stale.id} removed")
    end

    it 'rolls back the removal of a creator whose team still has other members' do
      stale = old_user(confirmed_at: nil, confirmation_token: 'tok-stale2')
      team = create(:team, created_by: stale)
      other = create(:user)
      create(:user_assignment, user: other, assignable: team, user_role: UserRole.find_predefined_owner_role)

      run_task('data:clean_unconfirmed_users')

      # teams.created_by_id still references the creator, so the removal is rolled back and logged
      expect(log_io.string).to include("Failed to destroy unconfirmed user #{stale.id}")
      expect(User.exists?(stale.id)).to be true
      expect(Team.exists?(team.id)).to be true
    end

    it 'removes invited users whose invitation expired' do
      invited = old_user(confirmed_at: nil, confirmation_token: nil, invitation_token: 'inv-tok',
                         invitation_accepted_at: nil)
      accepted = old_user(confirmed_at: nil, confirmation_token: nil, invitation_token: 'inv-tok2',
                          invitation_accepted_at: 1.day.ago)

      run_task('data:clean_unconfirmed_users')

      expect(User.exists?(invited.id)).to be false
      expect(User.exists?(accepted.id)).to be true
    end

    it 'removes unconfirmed users with an identity (unfinished LinkedIn signup)' do
      stale = old_user(confirmed_at: nil, confirmation_token: nil)
      create(:user_identity, user: stale)

      run_task('data:clean_unconfirmed_users')

      expect(User.exists?(stale.id)).to be false
    end

    it 'logs the failure and rolls back when a user cannot be destroyed' do
      stale = old_user(confirmed_at: nil, confirmation_token: 'tok-fail')
      allow_any_instance_of(User).to receive(:destroy!).and_raise(StandardError, 'cannot')

      run_task('data:clean_unconfirmed_users')

      expect(User.exists?(stale.id)).to be true
      expect(log_io.string).to include("Failed to destroy unconfirmed user #{stale.id}: cannot")
    end

    it 'skips the self-signup cleanup when confirm_within is not configured' do
      Devise.confirm_within = nil
      stale = old_user(confirmed_at: nil, confirmation_token: 'tok-nil')

      run_task('data:clean_unconfirmed_users')

      expect(User.exists?(stale.id)).to be true
    end

    it 'skips the invitation cleanup when invitations never expire' do
      Devise.invite_for = 0
      invited = old_user(confirmed_at: nil, confirmation_token: nil, invitation_token: 'inv-zero')

      run_task('data:clean_unconfirmed_users')

      expect(User.exists?(invited.id)).to be true
    end
  end

  describe 'data:clean' do
    it 'runs the temp files and unconfirmed users cleanups' do
      stale = create(:temp_file).tap { |f| f.update_columns(created_at: 5.days.ago) }

      expect { run_task('data:clean') }.to change(TempFile, :count).by(-1)
      expect(TempFile.exists?(stale.id)).to be false
      expect(log_io.string).to include('Cleaning unconfirmed users')
    end
  end

  describe 'team export and import' do
    let(:owner) { create(:user) }
    let!(:team) { create(:team, created_by: owner, name: 'Exported team') }
    let!(:project) do
      create(:project, team: team, created_by: owner,
                       default_public_user_role_id: UserRole.find_predefined_owner_role.id)
    end
    let!(:experiment) { create(:experiment, project: project, created_by: owner) }
    let!(:my_module) { create(:my_module, experiment: experiment, created_by: owner) }

    def exported_dir
      Dir.glob(File.join(tmp_dir, 'tmp', 'team_*_export_*')).first
    end

    before { without_transaction_isolation }

    def export_team
      Dir.chdir(tmp_dir) do
        expect { run_task('data:team_export', team.id.to_s) }.to output(/Done!/).to_stdout
      end
    end

    describe 'data:team_export' do
      it 'writes the team structure json and reports counts' do
        output = nil
        Dir.chdir(tmp_dir) do
          expect { run_task('data:team_export', team.id.to_s) }.to(
            output(/Exported projects: 1.*Done!/m).to_stdout
          )
        end

        json = JSON.parse(File.read(File.join(exported_dir, 'team_export.json')))
        expect(json['team']['name']).to eq 'Exported team'
        expect(json['default_admin_id']).to eq owner.id
        expect(json['users'].size).to eq 1
        expect(output).to be_nil
        expect(log_io.string).to include("Exporting team with ID:#{team.id}")
      end

      it 'raises when the team does not exist' do
        Dir.chdir(tmp_dir) do
          expect { run_task('data:team_export', '0') }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    describe 'data:team_import' do
      it 'imports an exported team as a new team with its projects' do
        export_team
        # the import creates the exported users again, so free their emails first
        owner.update_columns(email: 'original-owner@example.com')

        expect do
          expect { run_task('data:team_import', exported_dir) }.to output.to_stdout
        end.to change(Team, :count).by(1)

        imported = Team.where(name: 'Exported team').order(:id).last
        expect(imported.id).not_to eq team.id
        expect(imported.projects.pluck(:name)).to eq [project.name]
        expect(imported.projects.first.experiments.pluck(:name)).to eq [experiment.name]
        expect(log_io.string).to include("Importing team from directory #{exported_dir}")
      end

      it 'imports repositories, rows, steps, results, comments and tags together with the team' do
        repository = create(:repository, team: team, created_by: owner, name: 'Exported repository')
        row = create(:repository_row, repository: repository, created_by: owner, name: 'Exported row')
        column = create(:repository_column, repository: repository, created_by: owner,
                                            data_type: :RepositoryTextValue, name: 'Exported column')
        text_value = create(:repository_text_value, data: 'cell data', created_by: owner, last_modified_by: owner)
        create(:repository_cell, repository_row: row, repository_column: column, value: text_value)
        step = create(:step, protocol: my_module.protocol, user: owner, name: 'Exported step')
        create(:step_comment, step: step, user: owner, message: 'step comment')
        result = create(:result, my_module: my_module, user: owner, name: 'Exported result')
        create(:result_text, result: result, text: 'result text')
        create(:task_comment, my_module: my_module, user: owner, message: 'task comment')
        create(:project_comment, project: project, user: owner, message: 'project comment')
        tag = create(:tag, team: team, name: 'Exported tag')
        create(:tagging, taggable: my_module, tag: tag)
        export_team
        owner.update_columns(email: 'original-owner@example.com')

        expect { run_task('data:team_import', exported_dir) }.to output(/Imported repositories: 1/).to_stdout

        imported = Team.where(name: 'Exported team').order(:id).last
        imported_repository = imported.repositories.find_by(name: 'Exported repository')
        expect(imported_repository.repository_rows.pluck(:name)).to eq ['Exported row']
        expect(imported_repository.repository_rows.first.repository_cells.first.value.data).to eq 'cell data'
        imported_module = imported.projects.first.experiments.first.my_modules.first
        expect(imported_module.protocol.steps.pluck(:name)).to eq ['Exported step']
        expect(imported_module.results.pluck(:name)).to eq ['Exported result']
        expect(imported_module.task_comments.pluck(:message)).to eq ['task comment']
        expect(imported.projects.first.project_comments.pluck(:message)).to eq ['project comment']
        expect(imported.tags.pluck(:name)).to eq ['Exported tag']
      end

      it 'fails when the directory has no export file' do
        expect { run_task('data:team_import', tmp_dir) }.to raise_error(Errno::ENOENT)
      end
    end

    describe 'data:experiment_template_export' do
      it 'exports the experiment structure to a directory' do
        dir = nil
        Dir.chdir(tmp_dir) do
          expect { run_task('data:experiment_template_export', experiment.id.to_s) }.to(
            output(/Exported assets: 0.*Done!/m).to_stdout
          )
          dir = Dir.glob(File.join(tmp_dir, 'tmp', 'experiment_*_export_*')).first
        end

        json = JSON.parse(File.read(File.join(dir, 'experiment.json')))
        expect(json.dig('experiment', 'name')).to eq experiment.name
        expect(json['my_modules'].map { |m| m.dig('my_module', 'name') }).to eq [my_module.name]
        expect(log_io.string).to include("Exporting experiment template with ID:#{experiment.id}")
      end
    end

    describe 'data:experiment_template_import' do
      it 'imports an exported experiment into a project under a unique name' do
        dir = nil
        Dir.chdir(tmp_dir) do
          expect { run_task('data:experiment_template_export', experiment.id.to_s) }.to output.to_stdout
          dir = Dir.glob(File.join(tmp_dir, 'tmp', 'experiment_*_export_*')).first
        end

        # bug: app/services/team_importer.rb:1084 uses @user_roles, which is only set by #import_from_dir,
        # so importing an experiment template with user assignments raises NoMethodError
        pending 'bug: TeamImporter#import_experiment_template_from_dir crashes on @user_roles'
        expect do
          expect do
            run_task('data:experiment_template_import', dir, project.id.to_s, owner.id.to_s)
          end.to output.to_stdout
        end.to change { project.experiments.count }.by(1)

        expect(project.experiments.pluck(:name)).to include("#{experiment.name} (1)")
      end
    end
  end

  describe 'data:team_delete' do
    let(:owner) { create(:user) }
    let!(:team) { create(:team, created_by: owner) }

    before do
      create(:project, team: team, created_by: owner,
                       default_public_user_role_id: UserRole.find_predefined_owner_role.id)
    end

    it 'deletes the team and its data' do
      original_db_logger = ActiveRecord::Base.logger
      begin
        expect { run_task('data:team_delete', team.id.to_s) }.to change(Team, :count).by(-1)
      ensure
        ActiveRecord::Base.logger = original_db_logger
      end
      expect(Team.exists?(team.id)).to be false
      expect(Project.where(team_id: team.id)).to be_empty
    end

    it 'raises when the team cannot be loaded' do
      expect { run_task('data:team_delete', '0') }.to raise_error(StandardError, 'Can not load team')
    end
  end

  describe 'data:update_all_templates' do
    around do |example|
      delay_jobs = Delayed::Worker.delay_jobs
      Delayed::Worker.delay_jobs = true
      example.run
    ensure
      Delayed::Worker.delay_jobs = delay_jobs
    end

    it 'enqueues one template update job per team, slice by slice' do
      teams = create_list(:team, 2)
      Delayed::Job.delete_all

      run_task('data:update_all_templates', '1')

      jobs = Delayed::Job.where(queue: 'templates').order(:run_at)
      expect(jobs.count).to eq Team.count
      expect(jobs.map(&:priority).uniq).to eq [5]
      expect(jobs.last.run_at - jobs.first.run_at).to be > 1.hour - 10.minutes if Team.count > 1
      expect(log_io.string).to include('Processing slice with index 0.')
      expect(log_io.string).to include("Processing slice with index #{Team.count - 1}.")
      expect(teams).to all(be_persisted)
    end

    it 'uses a default slice size of 800' do
      create(:team)
      Delayed::Job.delete_all

      run_task('data:update_all_templates')

      expect(log_io.string.scan('Processing slice with index').size).to eq 1
    end
  end

  describe 'data:purge_experiment_workflow_images' do
    it 'removes the workflow image attachments' do
      experiment = create(:experiment)
      experiment.workflowimg.attach(io: StringIO.new('img'), filename: 'wf.png', content_type: 'image/png')
      expect(ActiveStorage::Attachment.where(name: 'workflowimg').count).to eq 1

      run_task('data:purge_experiment_workflow_images')

      expect(ActiveStorage::Attachment.where(name: 'workflowimg')).to be_empty
    end
  end

  describe 'data:cleanup_blobs' do
    it 'purges only blobs that are not attached' do
      orphan = ActiveStorage::Blob.create_and_upload!(io: StringIO.new('x'), filename: 'o.txt')
      experiment = create(:experiment)
      experiment.workflowimg.attach(io: StringIO.new('img'), filename: 'wf.png', content_type: 'image/png')
      attached = experiment.workflowimg.blob

      run_task('data:cleanup_blobs')

      expect(ActiveStorage::Blob.exists?(orphan.id)).to be false
      expect(ActiveStorage::Blob.exists?(attached.id)).to be true
    end
  end

  describe 'data:reset_predefined_user_roles' do
    it 'restores the permissions of an existing predefined role' do
      viewer = UserRole.find_by(name: I18n.t('user_roles.predefined.viewer')) || create(:viewer_role)
      viewer.update_column(:permissions, [])

      run_task('data:reset_predefined_user_roles')

      expect(viewer.reload.permissions).to match_array(PredefinedRoles::VIEWER_PERMISSIONS)
    end

    it 'creates a predefined role that is missing' do
      UserRole.where(name: I18n.t('user_roles.predefined.technician')).destroy_all

      expect { run_task('data:reset_predefined_user_roles') }.to change {
        UserRole.where(name: I18n.t('user_roles.predefined.technician')).count
      }.from(0).to(1)
      expect(UserRole.find_by(name: I18n.t('user_roles.predefined.technician')).permissions)
        .to match_array(PredefinedRoles::TECHNICIAN_PERMISSIONS)
    end
  end

  describe 'data:reset_repositories_user_assignments' do
    it 'creates automatic assignments of repositories for every team member' do
      owner = create(:user)
      team = create(:team, created_by: owner)
      owner_role = UserRole.find_predefined_owner_role
      repository = create(:repository, team: team, created_by: owner)
      repository.user_assignments.where(user: owner).destroy_all

      run_task('data:reset_repositories_user_assignments')

      assignment = repository.user_assignments.find_by(user: owner)
      expect(assignment).to be_present
      expect(assignment.user_role).to eq owner_role
      expect(assignment.assigned).to eq 'automatically'
      expect(assignment.team).to eq team
    end
  end

  describe 'data:reset_protocols_creator_user_assignments' do
    it 'gives the creator of a repository protocol the owner role when missing' do
      owner = create(:user)
      team = create(:team, created_by: owner)
      protocol = create(:protocol, :in_repository_published_original, team: team, added_by: owner)
      protocol.user_assignments.destroy_all

      run_task('data:reset_protocols_creator_user_assignments')

      assignment = protocol.user_assignments.find_by(user: owner)
      expect(assignment.user_role).to eq UserRole.find_predefined_owner_role
      expect(assignment.assigned).to eq 'manually'
      expect(assignment.assigned_by).to eq owner
    end
  end

  describe 'data:extract_missing_asset_texts' do
    it 'extracts text for text-like assets without text data' do
      asset = create(:asset)
      asset.file.attach(io: StringIO.new('%PDF-1.4'), filename: 'a.pdf', content_type: 'application/pdf')
      asset.asset_text_datum&.destroy

      # bug: lib/tasks/data.rake:233 calls Asset#extract_asset_text, which does not exist (NoMethodError)
      pending 'bug: Asset#extract_asset_text is not defined'
      run_task('data:extract_missing_asset_texts')

      expect(asset.reload.asset_text_datum).to be_present
    end
  end
end
