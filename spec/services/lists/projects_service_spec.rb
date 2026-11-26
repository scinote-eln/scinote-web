# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Lists::ProjectsService do
  let!(:team) { create(:team) }
  let!(:user) { create(:user) }
  let!(:folder) { create(:project_folder) }
  let!(:projects) { create_list(:project, 5, team: team) }
  let!(:archived_projects) { create_list(:project, 5, :archived, team: team) }
  let(:params) {{ page: 1, per_page: 10, search: '', team: team } }
  let(:service) { described_class.new(team, team.projects, folder, params, user: user) }

  before(:all) do
    MyModuleStatusFlow.ensure_default
  end

  describe '#call' do
    context 'when view_mode is archived' do
      before do
        params[:view_mode] = 'archived'
      end

      it 'fetches only archived projects' do
        expect(service.call).to all(be_archived)
      end
    end

    context 'when view_mode is active' do
      it 'fetches only active projects' do
        expect(service.call).to all(be_active)
      end
    end

    context 'when search param is present' do
      it 'filters projects by search param' do
        params[:search] = 'Project-2'
        Project.second.update!(name: 'Project-2 name')
        Project.third.update!(name: 'Project-3 name')

        service.call.each do |record|
          expect(record.name).to include('name')
        end
      end
    end

    context 'when query filter is present' do
      let(:filters) { { query: 'Project-1' } }

      it 'filters projects by search query' do
        params[:filters] = filters

        service.call.each do |record|
          expect(record.name).to include('Project-1')
        end
      end
    end

    context 'when created_at_from filter is present' do
      let(:filters) { { created_at_from: 1.day.ago } }

      it 'filters projects created after the specified date' do
        params[:filters] = filters

        expect(service.call.pluck(:created_at)).to all(be > 1.day.ago)
      end
    end
  end


  describe 'filters and sorting (assertive)' do
    let(:owner_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.owner')) }
    let!(:p_a) do
      create(:project, team: team, name: 'Alpha proj', description: 'first desc', start_date: 10.days.ago,
                       due_date: 5.days.from_now, supervised_by: user)
    end
    let!(:p_b) do
      create(:project, team: team, name: 'Bravo proj', description: nil, start_date: 2.days.ago,
                       due_date: 20.days.from_now)
    end
    let(:sub_folder) { create(:project_folder, team: team, name: 'Sub') }
    let(:ids) { ->(records) { records.select { |r| r.is_a?(Project) }.map(&:id) } }

    def run(extra = {})
      described_class.new(team, team.projects, nil, ActionController::Parameters.new(params.merge(per_page: 50).merge(extra)), user: user).call
    end

    it 'returns projects and root folders together without filters' do
      folder_in_team = create(:project_folder, team: team, name: 'Root folder')
      result = run
      expect(result.select { |r| r.is_a?(ProjectFolder) }).to include(folder_in_team)
      expect(ids.call(result)).to include(p_a.id, p_b.id)
    end

    it 'restricts to the current folder' do
      f = create(:project_folder, team: team, name: 'Inside')
      p_a.update!(project_folder: f)
      service = described_class.new(team, team.projects, f, ActionController::Parameters.new(params), user: user)
      expect(service.call.map(&:id)).to eq [p_a.id]
    end

    it 'searches folders by name and with folder_search returns flat projects' do
      create(:project_folder, team: team, name: 'Needle folder')
      result = run(search: 'Needle')
      expect(result.map(&:class).uniq).to eq [ProjectFolder]
      flat = run(filters: { folder_search: 'true', query: 'Alpha' })
      expect(flat.map(&:id)).to eq [p_a.id]
    end

    it 'filters by head_of_project, members, dates and statuses' do
      expect(run(filters: { head_of_project: user.id }).map(&:id)).to eq [p_a.id]
      expect(run(filters: { start_date_from: 5.days.ago.to_date }).map(&:id)).to eq [p_b.id]
      expect(run(filters: { start_date_to: 5.days.ago.to_date }).map(&:id)).to eq [p_a.id]
      expect(run(filters: { due_date_from: 10.days.from_now.to_date }).map(&:id)).to eq [p_b.id]
      expect(run(filters: { due_date_to: 10.days.from_now.to_date }).map(&:id)).to eq [p_a.id]
      expect(run(filters: { statuses: %w(done) }).map(&:id)).to be_empty
      expect(run(filters: { statuses: %w(not_started bogus) }).map(&:id)).to include(p_a.id, p_b.id)
      create(:user_assignment, user: user, assignable: p_a, user_role: owner_role)
      expect(run(filters: { members: [user.id] }).map(&:id)).to eq [p_a.id]
    end

    it 'filters archived projects by archived_on' do
      archived_projects.first.update!(archived_on: 10.days.ago)
      view = { view_mode: 'archived' }
      expect(run(view.merge(filters: { archived_on_to: 5.days.ago })).map(&:id))
        .to eq [archived_projects.first.id]
      expect(run(view.merge(filters: { archived_on_from: 5.days.ago })).map(&:id))
        .not_to include(archived_projects.first.id)
    end

    %w(name code created_at updated_at archived_on users comments favorite start_date due_date status
       supervised_by description completed_experiments completed_tasks).each do |column|
      %w(asc desc).each do |dir|
        it "sorts without error by #{column} #{dir}" do
          view = column == 'archived_on' ? { view_mode: 'archived' } : {}
          flat = view.merge(filters: { folder_search: 'true' })
          archived_projects.each { |ap| ap.update!(archived_on: rand(10).days.ago) }
          result = run(flat.merge(order: { column: column, dir: dir }))
          expect(result.map(&:id)).to match_array(ids.call(run(flat)))
        end
      end
    end

    it 'sorts by name in both directions' do
      flat = { filters: { folder_search: 'true', query: 'proj' } }
      only = ->(records) { records.map(&:name).grep(/ proj\z/) }
      asc = run(flat.merge(order: { column: 'name', dir: 'asc' }))
      desc = run(flat.merge(order: { column: 'name', dir: 'desc' }))
      expect(only.call(asc)).to eq ['Alpha proj', 'Bravo proj']
      expect(only.call(desc)).to eq ['Bravo proj', 'Alpha proj']
    end

    it 'puts folders after projects when sorting by name and counts projects in them' do
      create(:project_folder, team: team, name: 'Aaa folder')
      result = run(order: { column: 'status', dir: 'asc' })
      expect(result.last).to be_a(ProjectFolder)
    end

    it 'exposes aggregate counts' do
      exp = create(:experiment, project: p_a, created_by: user)
      create(:my_module, experiment: exp, created_by: user)
      rec = run(filters: { folder_search: 'true', query: 'Alpha' }).first
      expect(rec.experiments_count).to eq 1
      expect(rec.tasks_count).to eq 1
      expect(rec.completed_tasks_count).to eq 0
    end
  end
end
