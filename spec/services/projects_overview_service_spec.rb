# frozen_string_literal: true

require 'rails_helper'

describe ProjectsOverviewService do
  PROJECTS_CNT = 26
  time = Time.new(2015, 8, 1, 14, 35, 0)
  let!(:user) { create :user }
  let!(:another_user) { create :user }
  let!(:team) { create :team, created_by: user }
  let!(:another_team) { create :team, created_by: another_user }
  before do
    @projects_overview = ProjectsOverviewService.new(team, user, nil, params)
  end

  let!(:project_1) do
    create :project, name: 'test project D', visibility: 1, team: team,
                     archived: false, created_at: time.advance(hours: 2), created_by: user
  end
  let!(:project_2) do
    create :project, name: 'test project B', visibility: 1, team: team,
                     archived: true, created_at: time, created_by: user
  end
  let!(:project_3) do
    create :project, name: 'test project C', visibility: 1, team: team,
                     archived: false, created_at: time.advance(hours: 3), created_by: user
  end
  let!(:project_4) do
    create :project, name: 'test project A', visibility: 1, team: team,
                     archived: true, created_at: time.advance(hours: 1), created_by: user
  end
  let!(:project_5) do
    create :project, name: 'test project E', visibility: 1, team: team,
                     archived: true, created_at: time.advance(hours: 5), created_by: user
  end
  let!(:project_6) do
    create :project, name: 'test project F', visibility: 0, team: another_team,
                     archived: false, created_at: time.advance(hours: 4), created_by: another_user
  end

  (7..PROJECTS_CNT).each do |i|
    let!("project_#{i}") do
      create :project, name: "test project #{(64 + i).chr}",
                       visibility: 1,
                       team: team, archived: i % 2,
                       created_at: time.advance(hours: 6, minutes: i),
                       created_by: user
    end
  end

  describe '#project_cards' do
    let(:params) { {} }

    context 'with request parameters {  }' do
      it 'returns all projects' do
        projects = @projects_overview.project_cards
        expect(projects).to include(project_1, project_2, project_3, project_4,
                                    project_5)
        expect(projects).not_to include project_6
        expect(projects.length).to eq PROJECTS_CNT - 1
        expect(projects.uniq.length).to eq projects.length
      end
    end

    context "with request parameters { filter: 'active' }" do
      let(:params) { { view_mode: 'active' } }

      it 'returns all active projects' do
        projects = @projects_overview.project_cards
        expect(projects.length).to eq PROJECTS_CNT / 2 - 1
        expect(projects.uniq.length).to eq projects.length
        expect(projects).to include(project_1, project_3)
        expect(projects).not_to include(project_2, project_4, project_5,
                                        project_6)
      end

      context "with request parameters { sort: 'old' }" do
        let(:params) { super().merge(sort: 'old') }

        it 'returns all active projects, sorted by ascending creation ' \
           'time attribute' do
          projects = @projects_overview.project_cards
          expect(projects.length).to eq PROJECTS_CNT / 2 - 1
          expect(projects.uniq.length).to eq projects.length
          expect(projects.first(2)).to eq [project_1, project_3]
          expect(projects).not_to include(project_2, project_4, project_5,
                                          project_6)
        end
      end

      context "with request parameters { sort: 'new' }" do
        let(:params) { super().merge(sort: 'new') }

        it 'returns all active projects, sorted by descending creation ' \
           'time attribute' do
          projects = @projects_overview.project_cards
          expect(projects.length).to eq PROJECTS_CNT / 2 - 1
          expect(projects.uniq.length).to eq projects.length
          expect(projects.last(2)).to eq [project_3, project_1]
          expect(projects).not_to include(project_2, project_4, project_5,
                                          project_6)
        end
      end

      context "with request parameters { sort: 'atoz' }" do
        let(:params) { super().merge(sort: 'atoz') }

        it 'returns all active projects, sorted by ascending name ' \
           'attribute' do
          projects = @projects_overview.project_cards
          expect(projects.length).to eq PROJECTS_CNT / 2 - 1
          expect(projects.uniq.length).to eq projects.length
          expect(projects.first(2)).to eq [project_3, project_1]
          expect(projects).not_to include(project_2, project_4, project_5,
                                          project_6)
        end
      end

      context "with request parameters { sort: 'ztoa' }" do
        let(:params) { super().merge(sort: 'ztoa') }

        it 'returns all active projects, sorted by descending name ' \
           ' attribute' do
          projects = @projects_overview.project_cards
          expect(projects.length).to eq PROJECTS_CNT / 2 - 1
          expect(projects.uniq.length).to eq projects.length
          expect(projects.last(2)).to eq [project_1, project_3]
          expect(projects).not_to include(project_2, project_4, project_5,
                                          project_6)
        end
      end
    end

    context "with request parameters { filter: 'archived' }" do
      let(:params) { super().merge(view_mode: 'archived') }

      it 'returns all archived projects' do
        projects = @projects_overview.project_cards
        expect(projects.length).to eq PROJECTS_CNT / 2
        expect(projects.uniq.length).to eq projects.length
        expect(projects).to include(project_2, project_4, project_5)
        expect(projects).not_to include(project_1, project_3, project_6)
      end

      context "with request parameters { sort: 'old' }" do
        let(:params) { super().merge(sort: 'old') }

        it 'returns all archived projects, sorted by ascending creation ' \
           'time attribute' do
          projects = @projects_overview.project_cards
          expect(projects.length).to eq PROJECTS_CNT / 2
          expect(projects.uniq.length).to eq projects.length
          expect(projects.first(3)).to eq [project_2, project_4, project_5]
          expect(projects).not_to include(project_1, project_3, project_6)
        end
      end

      context "with request parameters { sort: 'new' }" do
        let(:params) { super().merge(sort: 'new') }

        it 'returns all archived projects, sorted by descending creation ' \
           'time attribute' do
          projects = @projects_overview.project_cards
          expect(projects.length).to eq PROJECTS_CNT / 2
          expect(projects.uniq.length).to eq projects.length
          expect(projects.last(3)).to eq [project_5, project_4, project_2]
          expect(projects).not_to include(project_1, project_3, project_6)
        end
      end

      context "with request parameters { sort: 'atoz' }" do
        let(:params) { super().merge(sort: 'atoz') }

        it 'returns all archived projects, sorted by ascending name ' \
           ' attribute' do
          projects = @projects_overview.project_cards
          expect(projects.length).to eq PROJECTS_CNT / 2
          expect(projects.uniq.length).to eq projects.length
          expect(projects.first(3)).to eq [project_4, project_2, project_5]
          expect(projects).not_to include(project_1, project_3, project_6)
        end
      end

      context "with request parameters { sort: 'ztoa' }" do
        let(:params) { super().merge(sort: 'ztoa') }

        it 'returns all archived projects, sorted by descending name ' \
           ' attribute' do
          projects = @projects_overview.project_cards
          expect(projects.length).to eq PROJECTS_CNT / 2
          expect(projects.uniq.length).to eq projects.length
          expect(projects.last(3)).to eq [project_5, project_2, project_4]
          expect(projects).not_to include(project_1, project_3, project_6)
        end
      end
    end
  end
end
