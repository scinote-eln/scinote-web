# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Lists::MyModulesService do
  let!(:user) { create(:user) }
  let!(:project) { create(:project, created_by: user) }
  let!(:experiment) { create(:experiment, project: project, created_by: user) }
  let!(:my_modules) { create_list(:my_module, 5, experiment: experiment) }
  let!(:archived_my_modules) { create_list(:my_module, 5, :archived, experiment: experiment) }
  let(:raw_data) { experiment.my_modules }
  let(:params) {{ page: 1, per_page: 10, search: '', experiment: experiment } }
  let(:service) { described_class.new(raw_data, params, user:) }

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
        params[:search] = 'Module-2'
        MyModule.second.update!(description: 'Module-2 description')
        MyModule.third.update!(description: 'Module-2 description')

        service.call do |record|
          expect(record.description).to include('description')
        end
      end
    end

    context 'when query filter is present' do
      let(:filters) { { query: 'Module-1' } }

      it 'filters records by search query' do
        service.call do |record|
          expect(record.name).to include('Module-1')
        end
      end
    end
  end


  describe 'assertive filtering and sorting' do
    let!(:t_a) { create(:my_module, experiment: experiment, name: 'Sample Alpha', due_date: 2.days.from_now) }
    let!(:t_b) { create(:my_module, experiment: experiment, name: 'Sample Bravo', due_date: 20.days.from_now) }

    def run(extra = {})
      described_class.new(raw_data, ActionController::Parameters.new(params.merge(per_page: 50).merge(extra)), user: user).call
    end

    def sorted(column, dir)
      run(search: 'Sample', order: { column: column, dir: dir }).to_a
    end

    it 'returns archived tasks when view_mode is archived and all active otherwise' do
      expect(run.to_a).to include(t_a, t_b)
      expect(run.to_a).not_to include(*archived_my_modules)
      expect(run(view_mode: 'archived').to_a).to match_array(archived_my_modules)
    end

    it 'ignores view_mode and lists all tasks when the experiment is archived' do
      experiment.update_columns(archived: true, archived_on: Time.zone.now)
      expect(run(view_mode: 'active').to_a).to include(t_a, t_b, *archived_my_modules)
    end

    it 'searches by name and filters by query' do
      expect(run(search: 'Alpha').to_a).to eq [t_a]
      expect(run(filters: { query: 'Bravo' }).to_a).to eq [t_b]
    end

    it 'filters by due date range' do
      expect(run(filters: { due_date_from: 10.days.from_now }).to_a).to eq [t_b]
      expect(run(filters: { due_date_to: 10.days.from_now }).to_a).to eq [t_a]
    end

    it 'filters by archived_on range' do
      archived_my_modules.first.update!(archived_on: 10.days.ago)
      expect(run(view_mode: 'archived', filters: { archived_on_to: 5.days.ago }).to_a)
        .to eq [archived_my_modules.first]
      expect(run(view_mode: 'archived', filters: { archived_on_from: 5.days.ago }).to_a)
        .not_to include(archived_my_modules.first)
    end

    it 'filters by designated users, statuses and tags' do
      create(:user_my_module, my_module: t_a, user: user, assigned_by: user)
      tag = create(:tag, team: project.team)
      create(:tagging, taggable: t_b, tag: tag)
      expect(run(filters: { designated_users: [user.id] }).to_a).to eq [t_a]
      expect(run(filters: { tags: [tag.id] }).to_a).to eq [t_b]
      expect(run(filters: { statuses: [t_a.my_module_status_id] }).to_a).to include(t_a)
      expect(run(filters: { statuses: [0] }).to_a).to be_empty
    end

    it 'sorts by name and id in both directions' do
      expect(sorted('name', 'asc').map(&:name)).to eq ['Sample Alpha', 'Sample Bravo']
      expect(sorted('name', 'desc').map(&:name)).to eq ['Sample Bravo', 'Sample Alpha']
      expect(sorted('code', 'asc').map(&:id)).to eq [t_a.id, t_b.id]
      expect(sorted('code', 'desc').map(&:id)).to eq [t_b.id, t_a.id]
    end

    it 'sorts by due date and age' do
      expect(sorted('due_date', 'asc').map(&:id)).to eq [t_a.id, t_b.id]
      expect(sorted('due_date', 'desc').map(&:id)).to eq [t_b.id, t_a.id]
      expect(sorted('age', 'asc').map(&:id)).to eq [t_b.id, t_a.id]
      expect(sorted('age', 'desc').map(&:id)).to eq [t_a.id, t_b.id]
    end

    it 'sorts by count based columns' do
      create(:task_comment, my_module: t_b, user: user)
      expect(sorted('comments', 'desc').first).to eq t_b
      expect(sorted('comments', 'asc').last).to eq t_b
      create(:user_my_module, my_module: t_a, user: user, assigned_by: user)
      expect(sorted('designated', 'desc').first).to eq t_a
      expect(sorted('designated', 'asc').last).to eq t_a
      tag = create(:tag, team: project.team)
      create(:tagging, taggable: t_b, tag: tag)
      expect(sorted('tags', 'desc').first).to eq t_b
      expect(sorted('tags', 'asc').last).to eq t_b
    end

    %w(start_date archived_on status results favorite report).each do |column|
      %w(asc desc).each do |dir|
        it "sorts by #{column} #{dir} without losing records" do
          expect(sorted(column, dir)).to match_array([t_a, t_b])
        end
      end
    end
  end
end
