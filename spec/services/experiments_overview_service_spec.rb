# frozen_string_literal: true

require 'rails_helper'

describe ExperimentsOverviewService do
  EXPERIMENTS_CNT = 26
  time = Time.new(2019, 8, 1, 14, 35, 0)
  let!(:user) { create :user }
  let!(:project) { create :project, created_by: user }
  before do
    @experiments_overview = ExperimentsOverviewService.new(project, user, params)
  end

  let!(:experiment_1) do
    create :experiment, name: 'test experiment D', project: project,
                     archived: false, created_at: time.advance(hours: 2)
  end
  let!(:experiment_2) do
    create :experiment, name: 'test experiment B', project: project,
                     archived: true, archived_on: time.advance(hours: 9), archived_by: user, created_at: time
  end
  let!(:experiment_3) do
    create :experiment, name: 'test experiment C', project: project,
                     archived: false, created_at: time.advance(hours: 3)
  end
  let!(:experiment_4) do
    create :experiment, name: 'test experiment A', project: project,
                     archived: true, archived_on: time.advance(hours: 8), archived_by: user,
                     created_at: time.advance(hours: 1)
  end
  let!(:experiment_5) do
    create :experiment, name: 'test experiment E', project: project,
                     archived: true, archived_on: time.advance(hours: 10), archived_by: user,
                     created_at: time.advance(hours: 5)
  end
  let!(:experiment_6) do
    create :experiment, name: 'test experiment F', project: project,
                     archived: false, created_at: time.advance(hours: 4)
  end
  (7..EXPERIMENTS_CNT).each do |i|
    let!("experiment_#{i}") do
      create :experiment, name: "test experiment #{(64 + i).chr}",
                          project: project, created_at: time.advance(hours: 6, minutes: i)
    end
  end

  describe '#experiments' do
    let(:params) { {} }

    context "with request parameters { filter: 'active' }" do
      let(:params) { { view_mode: 'active' } }

      it 'returns all active experiments' do
        experiments = @experiments_overview.experiments
        expect(experiments.length).to eq EXPERIMENTS_CNT - 3
        expect(experiments.uniq.length).to eq experiments.length
        expect(experiments).to include(experiment_1, experiment_3)
        expect(experiments).not_to include(experiment_2, experiment_4, experiment_5)
      end

      context "with request parameters { sort: 'old' }" do
        let(:params) { super().merge(sort: 'old') }

        it 'returns all active experiments, sorted by ascending creation time attribute' do
          experiments = @experiments_overview.experiments
          expect(experiments.length).to eq EXPERIMENTS_CNT - 3
          expect(experiments.uniq.length).to eq experiments.length
          expect(experiments.first(2)).to eq [experiment_1, experiment_3]
          expect(experiments).not_to include(experiment_2, experiment_4, experiment_5)
        end
      end

      context "with request parameters { sort: 'new' }" do
        let(:params) { super().merge(sort: 'new') }

        it 'returns all active experiments, sorted by descending creation time attribute' do
          experiments = @experiments_overview.experiments
          expect(experiments.length).to eq EXPERIMENTS_CNT - 3
          expect(experiments.uniq.length).to eq experiments.length
          expect(experiments.last(2)).to eq [experiment_3, experiment_1]
          expect(experiments).not_to include(experiment_2, experiment_4, experiment_5)
        end
      end

      context "with request parameters { sort: 'atoz' }" do
        let(:params) { super().merge(sort: 'atoz') }

        it 'returns all active experiments, sorted by ascending name attribute' do
          experiments = @experiments_overview.experiments
          expect(experiments.length).to eq EXPERIMENTS_CNT - 3
          expect(experiments.uniq.length).to eq experiments.length
          expect(experiments.first(2)).to eq [experiment_3, experiment_1]
          expect(experiments).not_to include(experiment_2, experiment_4, experiment_5)
        end
      end

      context "with request parameters { sort: 'ztoa' }" do
        let(:params) { super().merge(sort: 'ztoa') }

        it 'returns all active experiments, sorted by descending name attribute' do
          experiments = @experiments_overview.experiments
          expect(experiments.length).to eq EXPERIMENTS_CNT - 3
          expect(experiments.uniq.length).to eq experiments.length
          expect(experiments.last(2)).to eq [experiment_1, experiment_3]
          expect(experiments).not_to include(experiment_2, experiment_4, experiment_5)
        end
      end
    end

    context "with request parameters { filter: 'archived' }" do
      let(:params) { super().merge(view_mode: 'archived') }

      it 'returns all archived experiments' do
        experiments = @experiments_overview.experiments
        expect(experiments.length).to eq 3
        expect(experiments.uniq.length).to eq experiments.length
        expect(experiments).to include(experiment_2, experiment_4, experiment_5)
        expect(experiments).not_to include(experiment_1, experiment_3)
      end

      context "with request parameters { sort: 'old' }" do
        let(:params) { super().merge(sort: 'old') }

        it 'returns all archived experiments, sorted by ascending creation time attribute' do
          experiments = @experiments_overview.experiments
          expect(experiments.length).to eq 3
          expect(experiments.uniq.length).to eq experiments.length
          expect(experiments.first(3)).to eq [experiment_2, experiment_4, experiment_5]
          expect(experiments).not_to include(experiment_1, experiment_3, experiment_6)
        end
      end

      context "with request parameters { sort: 'new' }" do
        let(:params) { super().merge(sort: 'new') }

        it 'returns all archived experiments, sorted by descending creation time attribute' do
          experiments = @experiments_overview.experiments
          expect(experiments.length).to eq 3
          expect(experiments.uniq.length).to eq experiments.length
          expect(experiments.last(3)).to eq [experiment_5, experiment_4, experiment_2]
          expect(experiments).not_to include(experiment_1, experiment_3, experiment_6)
        end
      end

      context "with request parameters { sort: 'atoz' }" do
        let(:params) { super().merge(sort: 'atoz') }

        it 'returns all archived experiments, sorted by ascending name attribute' do
          experiments = @experiments_overview.experiments
          expect(experiments.length).to eq 3
          expect(experiments.uniq.length).to eq experiments.length
          expect(experiments.first(3)).to eq [experiment_4, experiment_2, experiment_5]
          expect(experiments).not_to include(experiment_1, experiment_3, experiment_6)
        end
      end

      context "with request parameters { sort: 'ztoa' }" do
        let(:params) { super().merge(sort: 'ztoa') }

        it 'returns all archived experiments, sorted by descending name attribute' do
          experiments = @experiments_overview.experiments
          expect(experiments.length).to eq 3
          expect(experiments.uniq.length).to eq experiments.length
          expect(experiments.last(3)).to eq [experiment_5, experiment_2, experiment_4]
          expect(experiments).not_to include(experiment_1, experiment_3, experiment_6)
        end
      end
    end
  end
end
