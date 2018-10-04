# frozen_string_literal: true

require 'rails_helper'

describe ProjectsOverviewService do
  PROJECTS_CNT = 26
  time = Time.new(2015, 8, 1, 14, 35, 0)
  let!(:user) { create :user }
  let!(:team) { create :team }
  let!(:projects_overview) do
    ProjectsOverviewService.new(team, user)
  end

  let!(:project_1) do
    create :project, name: 'test project D', visibility: 1, team: team,
                     archived: false, created_at: time.advance(hours: 2)
  end
  let!(:project_2) do
    create :project, name: 'test project B', visibility: 1, team: team,
                     archived: true, created_at: time
  end
  let!(:project_3) do
    create :project, name: 'test project C', visibility: 1, team: team,
                     archived: false, created_at: time.advance(hours: 3)
  end
  let!(:project_4) do
    create :project, name: 'test project A', visibility: 1, team: team,
                     archived: true, created_at: time.advance(hours: 1)
  end
  let!(:project_5) do
    create :project, name: 'test project E', visibility: 1, team: team,
                     archived: true, created_at: time.advance(hours: 5)
  end
  let!(:project_6) do
    create :project, name: 'test project F', visibility: 1, team: team,
                     archived: false, created_at: time.advance(hours: 4)
  end
  (7..PROJECTS_CNT).each do |i|
    let!("project_#{i}") do
      create :project, name: "test project #{(64 + i).chr}",
                       visibility: 1,
                       team: team, archived: i % 2,
                       created_at: time.advance(hours: 6, minutes: i)
    end
  end

  describe '#project_cards' do
    context 'with no parameters' do
      let(:params) { {} }

      it 'returns all projects' do
        projects = projects_overview.project_cards(params)
        expect(projects).to include(project_1, project_2, project_3, project_4,
                                    project_5, project_6)
        expect(projects.length).to eq PROJECTS_CNT
        expect(projects.uniq.length).to eq projects.length
      end
    end

    context "with 'filter: active' request parameter" do
      let(:params) { { filter: 'active' } }

      it 'returns all active projects' do
        projects = projects_overview.project_cards(params)
        expect(projects.length).to eq PROJECTS_CNT / 2
        expect(projects.uniq.length).to eq projects.length
        expect(projects).to include(project_1, project_3, project_6)
        expect(projects).not_to include(project_2, project_4, project_5)
      end

      context "with 'sort: old' request parameter" do
        let(:params) { super().merge(sort: 'old') }

        it 'returns all active projects, sorted by ascending creation time ' \
           ' attribute' do
          projects = projects_overview.project_cards(params)
          expect(projects.length).to eq PROJECTS_CNT / 2
          expect(projects.uniq.length).to eq projects.length
          expect(projects.first(3)).to eq [project_1, project_3, project_6]
          expect(projects).not_to include(project_2, project_4, project_5)
        end
      end

      context "with 'sort: new' request parameter" do
        let(:params) { super().merge(sort: 'new') }

        it 'returns all active projects, sorted by descending creation time ' \
           ' attribute' do
          projects = projects_overview.project_cards(params)
          expect(projects.length).to eq PROJECTS_CNT / 2
          expect(projects.uniq.length).to eq projects.length
          expect(projects.last(3)).to eq [project_6, project_3, project_1]
          expect(projects).not_to include(project_2, project_4, project_5)
        end
      end

      context "with 'sort: atoz' request parameter" do
        let(:params) { super().merge(sort: 'atoz') }

        it 'returns all active projects, sorted by ascending name ' \
           ' attribute' do
          projects = projects_overview.project_cards(params)
          expect(projects.length).to eq PROJECTS_CNT / 2
          expect(projects.uniq.length).to eq projects.length
          expect(projects.first(3)).to eq [project_3, project_1, project_6]
          expect(projects).not_to include(project_2, project_4, project_5)
        end
      end

      context "with 'sort: ztoa' request parameter" do
        let(:params) { super().merge(sort: 'ztoa') }

        it 'returns all active projects, sorted by descending name ' \
           ' attribute' do
          projects = projects_overview.project_cards(params)
          expect(projects.length).to eq PROJECTS_CNT / 2
          expect(projects.uniq.length).to eq projects.length
          expect(projects.last(3)).to eq [project_6, project_1, project_3]
          expect(projects).not_to include(project_2, project_4, project_5)
        end
      end
    end

    context "with 'filter: archive' request parameter" do
      let(:params) { { filter: 'archived' } }

      it 'returns all archived projects' do
        projects = projects_overview.project_cards(params)
        expect(projects.length).to eq PROJECTS_CNT / 2
        expect(projects.uniq.length).to eq projects.length
        expect(projects).to include(project_2, project_4, project_5)
        expect(projects).not_to include(project_1, project_3, project_6)
      end

      context "with 'sort: old' request parameter" do
        let(:params) { super().merge(sort: 'old') }

        it 'returns all archived projects, sorted by ascending creation time ' \
           ' attribute' do
          projects = projects_overview.project_cards(params)
          expect(projects.length).to eq PROJECTS_CNT / 2
          expect(projects.uniq.length).to eq projects.length
          expect(projects.first(3)).to eq [project_2, project_4, project_5]
          expect(projects).not_to include(project_1, project_3, project_6)
        end
      end

      context "with 'sort: new' request parameter" do
        let(:params) { super().merge(sort: 'new') }

        it 'returns all archived projects, sorted by descending creation ' \
           'time attribute' do
          projects = projects_overview.project_cards(params)
          expect(projects.length).to eq PROJECTS_CNT / 2
          expect(projects.uniq.length).to eq projects.length
          expect(projects.last(3)).to eq [project_5, project_4, project_2]
          expect(projects).not_to include(project_1, project_3, project_6)
        end
      end

      context "with 'sort: atoz' request parameter" do
        let(:params) { super().merge(sort: 'atoz') }

        it 'returns all archived projects, sorted by ascending name ' \
           ' attribute' do
          projects = projects_overview.project_cards(params)
          expect(projects.length).to eq PROJECTS_CNT / 2
          expect(projects.uniq.length).to eq projects.length
          expect(projects.first(3)).to eq [project_4, project_2, project_5]
          expect(projects).not_to include(project_1, project_3, project_6)
        end
      end

      context "with 'sort: ztoa' request parameter" do
        let(:params) { super().merge(sort: 'ztoa') }

        it 'returns all archived projects, sorted by descending name ' \
           ' attribute' do
          projects = projects_overview.project_cards(params)
          expect(projects.length).to eq PROJECTS_CNT / 2
          expect(projects.uniq.length).to eq projects.length
          expect(projects.last(3)).to eq [project_5, project_2, project_4]
          expect(projects).not_to include(project_1, project_3, project_6)
        end
      end
    end
  end

  describe '#projects_datatable' do
    context 'with no parameters' do
      let(:params) { {} }

      it 'returns projects, sorted by ascending archivation attribute (active' \
         ' first), offset by 0, paginated by 10' do
        projects = projects_overview.projects_datatable(params)
        expect(projects.length).to eq 10
        expect(projects.uniq.length).to eq projects.length
        expect(projects).not_to include(project_2, project_4, project_5)
        projects1 = projects.reject(&:archived?)
        expect(projects1.length).to eq 10
      end
    end

    context "with 'filter: active' request parameter" do
      let(:params) { { filter: 'active' } }

      it 'returns active projects, sorted by ascending archivation attribute' \
         '(active first), offset by 0, paginated by 10' do
        projects = projects_overview.projects_datatable(params)
        expect(projects.length).to eq 10
        expect(projects.uniq.length).to eq projects.length
        expect(projects).not_to include(project_2, project_4, project_5)
        projects1 = projects.reject(&:archived?)
        expect(projects1.length).to eq 10
      end

      context "with 'start: 15' request parameter" do
        let(:params) { super().merge(start: 15) }

        it 'returns active projects, sorted by ascending archivation ' \
           'attribute (active first), offset by 15, paginated by 10' do
          projects = projects_overview.projects_datatable(params)
          expect(projects.length).to eq 3
          expect(projects.uniq.length).to eq projects.length
          expect(projects).not_to include(project_1, project_2, project_3,
                                          project_4, project_5, project_6)
          projects1 = projects.reject(&:archived?)
          expect(projects1.length).to eq 3
        end
      end

      context "with 'length: 5' request parameter" do
        let(:params) { super().merge(length: 5) }

        it 'returns active projects, sorted by ascending archivation ' \
           'attribute (active first), offset by 0, paginated by 5' do
          projects = projects_overview.projects_datatable(params)
          expect(projects.length).to eq 5
          expect(projects.uniq.length).to eq projects.length
          expect(projects).not_to include(project_2, project_4, project_5)
          projects1 = projects.reject(&:archived?)
          expect(projects1.length).to eq 5
        end
      end

      context "with 'start: 13, length: 4' request parameters" do
        let(:params) { super().merge(start: 13, length: 4) }

        it 'returns active projects, sorted by ascending archivation ' \
           'attribute (active first), offset by 13, paginated by 4' do
          projects = projects_overview.projects_datatable(params)
          expect(projects.length).to eq 1
          expect(projects).not_to include(project_1, project_2, project_3,
                                          project_4, project_5, project_6)
          projects1 = projects.reject(&:archived?)
          expect(projects1.length).to eq 1
        end
      end
    end

    context "with 'filter: :archived' request parameter" do
      let(:params) { { filter: 'archived' } }

      it 'returns archived projects, sorted by ascending archivation ' \
         'attribute (active first), offset by 0, paginated by 10' do
        projects = projects_overview.projects_datatable(params)
        expect(projects.length).to eq 10
        expect(projects.uniq.length).to eq projects.length
        expect(projects).not_to include(project_1, project_3, project_6)
        projects1 = projects.select(&:archived?)
        expect(projects1.length).to eq 10
      end

      context "with 'start: 15' request parameter" do
        let(:params) { super().merge(start: 15) }

        it 'returns archived projects, sorted by ascending archivation ' \
           'attribute (active first), offset by 15, paginated by 10' do
          projects = projects_overview.projects_datatable(params)
          expect(projects.length).to eq 3
          expect(projects.uniq.length).to eq projects.length
          expect(projects).not_to include(project_1, project_2, project_3,
                                          project_4, project_5, project_6)
          projects1 = projects.select(&:archived?)
          expect(projects1.length).to eq 3
        end
      end

      context "with 'length: 5' request parameter" do
        let(:params) { super().merge(length: 5) }

        it 'returns archived projects, sorted by ascending archivation ' \
           'attribute (active first), offset by 0, paginated by 5' do
          projects = projects_overview.projects_datatable(params)
          expect(projects.length).to eq 5
          expect(projects.uniq.length).to eq projects.length
          expect(projects).not_to include(project_1, project_3, project_6)
          projects1 = projects.select(&:archived?)
          expect(projects1.length).to eq 5
        end
      end

      context "with 'start: 13, length: 4' parameters" do
        let(:params) { super().merge(start: 13, length: 4) }

        it 'returns archived projects, sorted by ascending archivation ' \
           'attribute (active first), offset by 13, paginated by 4' do
          projects = projects_overview.projects_datatable(params)
          expect(projects.length).to eq 1
          expect(projects).not_to include(project_1, project_2, project_3,
                                          project_4, project_5, project_6)
          projects1 = projects.select(&:archived?)
          expect(projects1.length).to eq 1
        end
      end
    end
  end
end
