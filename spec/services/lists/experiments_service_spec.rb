# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Lists::ExperimentsService do
  let!(:user) { create(:user) }
  let!(:project) { create(:project, created_by: user) }
  let!(:experiments) { create_list(:experiment, 5, project: project, created_by: user) }
  let!(:archived_experiments) { create_list(:experiment, 5, :archived, project: project, created_by: user) }
  let(:raw_data) { project.experiments }
  let(:params) {{ page: 1, per_page: 10, search: '', project: project } }
  let(:service) { described_class.new(raw_data, params, user:) }

  before(:all) do
    MyModuleStatusFlow.ensure_default
  end

  describe '#fetch_records' do
    context 'when view_mode is archived' do
      before do
        params[:view_mode] = 'archived'
      end

      it 'fetches only archived records' do
        expect(service.call).to all(be_archived)
      end
    end

    context 'when view_mode is active' do
      it 'fetches only active records' do
        expect(service.call).to all(be_active)
      end
    end
  end

  describe '#filter_records' do
    let(:filters) { {} }

    before do
      params[:filters] = filters
    end

    context 'when search param is present' do
      it 'filters records by search param' do
        params[:search] = 'Experiment-2'
        Experiment.second.update!(description: 'Experiment-2 description')
        Experiment.third.update!(description: 'Experiment-2 description')

        service.call do |record|
          expect(record.description).to include('description')
        end
      end
    end

    context 'when query filter is present' do
      let(:filters) { { query: 'Experiment-1' } }

      it 'filters records by search query' do
        service.call do |record|
          expect(record.name).to include('Experiment-1')
        end
      end
    end

    context 'when created_at_from filter is present' do
      let(:filters) { { created_at_from: 1.day.ago } }

      it 'filters records created after the specified date' do
        expect(service.call.pluck(:created_at)).to all(be > 1.day.ago)
      end
    end
  end


  describe 'assertive filtering and sorting' do
    let(:owner_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.owner')) }
    let!(:e_a) do
      create(:experiment, project: project, created_by: user, name: 'Sample Alpha', description: 'zzz first',
                          start_date: 10.days.ago, due_date: 3.days.from_now)
    end
    let!(:e_b) do
      create(:experiment, project: project, created_by: user, name: 'Sample Bravo', description: 'bbb',
                          start_date: 1.day.ago, due_date: 30.days.from_now)
    end

    before { user.permission_team = project.team }

    def run(extra = {})
      described_class.new(raw_data, ActionController::Parameters.new(params.merge(per_page: 50).merge(extra)), user: user).call
    end

    it 'returns only readable active experiments with task counts' do
      create(:my_module, experiment: e_a, created_by: user)
      rec = run(filters: { query: 'Alpha' }).first
      expect(rec).to eq e_a
      expect(rec.task_count).to eq 1
      expect(rec.completed_task_count).to eq 0
      expect(run.to_a).to include(e_a, e_b)
      expect(run.to_a).not_to include(*archived_experiments)
    end

    it 'returns archived experiments for archived view mode' do
      archived_experiments.first.update!(archived_on: 10.days.ago)
      expect(run(view_mode: 'archived').to_a).to match_array(archived_experiments)
      expect(run(view_mode: 'archived', filters: { archived_on_from: 5.days.ago }).to_a)
        .not_to include(archived_experiments.first)
      expect(run(view_mode: 'archived', filters: { archived_on_to: 5.days.ago }).to_a)
        .to eq [archived_experiments.first]
    end

    it 'ignores view_mode and lists all experiments when the project itself is archived' do
      project.update_columns(archived: true, archived_on: Time.zone.now)
      expect(run(view_mode: 'active').to_a).to include(e_a, e_b, *archived_experiments)
    end

    it 'filters by search, query, dates and updated_on' do
      expect(run(search: 'Alpha').to_a).to eq [e_a]
      expect(run(filters: { query: 'bbb' }).to_a).to eq [e_b]
      expect(run(filters: { start_date_from: 5.days.ago.to_date }).to_a).to eq [e_b]
      expect(run(filters: { start_date_to: 5.days.ago.to_date }).to_a).to eq [e_a]
      expect(run(filters: { due_date_from: 10.days.from_now.to_date }).to_a).to eq [e_b]
      expect(run(filters: { due_date_to: 10.days.from_now.to_date }).to_a).to include(e_a)
      expect(run(filters: { updated_on_from: 1.minute.from_now }).to_a).to be_empty
      expect(run(filters: { updated_on_to: 1.minute.from_now }).to_a).to include(e_a, e_b)
    end

    it 'filters by status' do
      e_b.update_columns(started_at: Time.zone.now)
      e_a.update_columns(started_at: Time.zone.now, done_at: Time.zone.now)
      expect(run(filters: { statuses: %w(done) }).to_a).to eq [e_a]
      expect(run(filters: { statuses: %w(in_progress) }).to_a).to eq [e_b]
      expect(run(filters: { statuses: %w(not_started) }).to_a).not_to include(e_a, e_b)
      expect(run(filters: { statuses: %w(bogus) }).to_a).to include(e_a, e_b)
    end

    it 'sorts by name both ways' do
      names = ->(dir) { run(search: 'Sample', order: { column: 'name', dir: dir }).map(&:name) }
      expect(names.call('asc')).to eq ['Sample Alpha', 'Sample Bravo']
      expect(names.call('desc')).to eq ['Sample Bravo', 'Sample Alpha']
    end

    %w(created_at code updated_at completed_tasks description start_date due_date status favorite
       report archived_on).each do |column|
      %w(asc desc).each do |dir|
        it "sorts by #{column} #{dir} without losing records" do
          result = run(search: 'Sample', order: { column: column, dir: dir })
          expect(result.map(&:id)).to match_array([e_a.id, e_b.id])
        end
      end
    end

    it 'ignores unknown sort columns' do
      expect(run(search: 'Sample', order: { column: 'nope', dir: 'asc' }).to_a.size).to eq 2
    end
  end
end
