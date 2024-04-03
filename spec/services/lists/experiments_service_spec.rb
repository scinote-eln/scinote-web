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
end
