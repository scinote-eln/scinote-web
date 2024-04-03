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
end
