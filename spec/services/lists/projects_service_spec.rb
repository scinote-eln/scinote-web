# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Lists::ProjectsService do
  let!(:team) { create(:team) }
  let!(:user) { create(:user) }
  let!(:folder) { create(:project_folder) }
  let!(:projects) { create_list(:project, 5, team: team) }
  let!(:archived_projects) { create_list(:project, 5, :archived, team: team) }
  let(:params) {{ page: 1, per_page: 10, search: '', team: team } }
  let(:service) { described_class.new(team, user, folder, params) }

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
end
