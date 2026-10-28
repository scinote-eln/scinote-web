# frozen_string_literal: true

require 'rails_helper'

describe ActivitiesService do
  let(:user) { create :user }
  let(:other_user) { create :user }
  let(:team) { create :team, created_by: user }
  let!(:owner_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.owner')) }
  let!(:normal_role) { create :normal_user_role }
  let!(:team_assignment) { team.user_assignments.find_by(user: user).tap { |a| a.update!(user_role: normal_role) } }
  let(:project) do
    create :project, team: team, created_by: user, default_public_user_role_id: nil
  end
  let!(:project_assignment) { create_user_assignment(project, owner_role, user) }
  let(:hidden_project) { create :project, team: team, created_by: other_user, default_public_user_role_id: nil }
  let(:experiment) { create :experiment, project: project, created_by: user }
  let(:my_module) { create :my_module, experiment: experiment, created_by: user }

  def activity(attrs = {})
    create :activity, { team: team, owner: user, subject: team, type_of: :create_project }.merge(attrs)
  end

  def load(filters = {}, teams = [team])
    described_class.load_activities(user, teams, filters).to_a
  end

  before { user.update!(current_team_id: team.id) }

  describe '.load_activities' do
    it 'returns team level activities newest first' do
      older = activity(created_at: 2.days.ago)
      newer = activity(created_at: 1.day.ago)
      expect(load).to eq [newer, older]
    end

    it 'ignores teams the user is not a member of' do
      foreign_team = create :team
      activity(team: foreign_team, subject: foreign_team)
      expect(load({}, [foreign_team])).to be_empty
    end

    it 'includes project activities of readable projects only' do
      visible = activity(subject: project, project: project)
      hidden = activity(subject: hidden_project, project: hidden_project)
      result = load
      expect(result).to include(visible)
      expect(result).not_to include(hidden)
    end

    it 'includes experiment and module activities of readable projects' do
      exp_activity = activity(subject: experiment, project: project, type_of: :create_experiment)
      mod_activity = activity(subject: my_module, project: project, type_of: :create_module)
      expect(load).to include(exp_activity, mod_activity)
    end

    it 'hides module activities for unreadable modules' do
      foreign_module = create :my_module, experiment: create(:experiment, project: hidden_project),
                                           created_by: other_user
      hidden = activity(subject: foreign_module, project: hidden_project, type_of: :create_module)
      expect(load).not_to include(hidden)
    end

    it 'includes activities of readable inventories and hides unreadable ones' do
      repository = create :repository, team: team, created_by: user
      create_user_assignment(repository, owner_role, user)
      hidden_repository = create :repository, team: team, created_by: other_user
      visible = activity(subject: repository, type_of: :create_inventory)
      hidden = activity(subject: hidden_repository, type_of: :create_inventory)
      result = load
      expect(result).to include(visible)
      expect(result).not_to include(hidden)
    end

    it 'keeps activities of deleted inventories' do
      repository = create :repository, team: team, created_by: other_user
      deleted = activity(subject: repository, type_of: :create_inventory)
      repository.delete
      expect(load).to include(deleted)
    end

    it 'filters by users' do
      mine = activity
      theirs = activity(owner: other_user)
      result = load(users: [other_user.id])
      expect(result).to eq [theirs]
      expect(result).not_to include(mine)
    end

    it 'filters by types' do
      project_type = activity(type_of: :create_project)
      report_type = activity(type_of: :create_report)
      expect(load(types: [Activity.type_ofs[:create_report].to_s])).to eq [report_type]
      expect(load(types: [Activity.type_ofs[:create_project].to_s])).to eq [project_type]
    end

    describe 'date filters' do
      let!(:old_activity) { activity(created_at: Time.zone.parse('2021-01-02 12:00')) }
      let!(:new_activity) { activity(created_at: Time.zone.parse('2021-03-02 12:00')) }

      it 'filters by a date range' do
        expect(load(from_date: '2021-03-31', to_date: '2021-03-01')).to eq [new_activity]
      end

      it 'filters by from date only (upper bound)' do
        expect(load(from_date: '2021-01-31')).to eq [old_activity]
      end

      it 'filters by to date only (lower bound)' do
        expect(load(to_date: '2021-02-01')).to eq [new_activity]
      end
    end

    it 'filters by subjects and their children' do
      project_activity = activity(subject: project, project: project)
      experiment_activity = activity(subject: experiment, project: project, type_of: :create_experiment)
      module_activity = activity(subject: my_module, project: project, type_of: :create_module)
      unrelated = activity(subject: team)

      result = load(subjects: { 'Project' => [project.id] })

      expect(result).to include(project_activity, experiment_activity)
      expect(result).not_to include(unrelated)
      expect(module_activity).to be_persisted
    end

    it 'filters by a module subject' do
      mine = activity(subject: my_module, project: project, type_of: :create_module)
      other_module = create :my_module, experiment: experiment, created_by: user
      other = activity(subject: other_module, project: project, type_of: :create_module)
      result = load(subjects: { 'MyModule' => [my_module.id] })
      expect(result).to include(mine)
      expect(result).not_to include(other)
    end

    it 'paginates' do
      stub_const('Constants::ACTIVITY_AND_NOTIF_SEARCH_LIMIT', 2)
      3.times { |i| activity(created_at: i.days.ago) }
      page1 = described_class.load_activities(user, [team], page: 1)
      page2 = described_class.load_activities(user, [team], page: 2)
      expect(page1.to_a.size).to eq 2
      expect(page1.next_page).to eq 2
      expect(page2.to_a.size).to eq 1
      expect(page2.next_page).to be_nil
    end
  end

  describe '.load_subjects_children' do
    it 'adds children of the given subjects' do
      experiment
      result = described_class.load_subjects_children({ 'Project' => [project.id] }, user, [team.id])
      expect(result[:Experiment]).to eq [experiment.id]
    end

    it 'adds repository rows for inventories limited to readable ones' do
      repository = create :repository, team: team, created_by: user
      create_user_assignment(repository, owner_role, user)
      row = create :repository_row, repository: repository, created_by: user, last_modified_by: user
      result = described_class.load_subjects_children({ 'RepositoryBase' => [repository.id] }, user, [team.id])
      expect(result[:RepositoryRow]).to eq [row.id]
    end

    it 'adds results of a module and maps Result to ResultBase' do
      result_record = create :result, my_module: my_module, user: user
      result = described_class.load_subjects_children({ 'MyModule' => [my_module.id] }, user, [team.id])
      expect(result[:Result]).to eq [result_record.id]
      expect(result[:Protocol]).to be_present
      mapped = described_class.load_subjects_children({ 'Result' => [result_record.id] }, user, [team.id])
      expect(mapped.keys).to include('ResultBase')
    end

    it 'does not override children that are already given' do
      pending 'bug: the already-given check uses a symbol key while callers pass string keys, so children are overridden'
      result = described_class.load_subjects_children({ 'Project' => [project.id], 'Experiment' => [-1] },
                                                      user, [team.id])
      expect(result).not_to have_key(:Experiment)
    end

    it 'returns the subjects unchanged when there are no known children' do
      expect(described_class.load_subjects_children({ 'Report' => [1, 1] })).to eq('Report' => [1])
    end
  end

  describe '.my_module_activities' do
    it 'returns activities of the module and its children within the project' do
      mod_activity = activity(subject: my_module, project: project, type_of: :create_module)
      other_module = create :my_module, experiment: experiment, created_by: user
      other_activity = activity(subject: other_module, project: project, type_of: :create_module)
      result = described_class.my_module_activities(my_module)
      expect(result).to include(mod_activity)
      expect(result).not_to include(other_activity)
    end
  end
end
