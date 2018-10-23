# frozen_string_literal: true

require 'rails_helper'

describe ProjectsOverviewService do
  PROJECTS_CNT = 26
  time = Time.new(2015, 8, 1, 14, 35, 0)
  let!(:user) { create :user }
  let!(:team) { create :team }
  before do
    @projects_overview = ProjectsOverviewService.new(team, user, params)
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
    create :project, name: 'test project F', visibility: 0, team: team,
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
      let(:params) { { filter: 'active' } }

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
      let(:params) { super().merge(filter: 'archived') }

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

  describe '#projects_datatable' do
    let(:params) { {} }

    context 'with request parameters { {} }' do
      it 'returns projects, sorted by ascending archivation attribute (active' \
         ' first), offset by 0, paginated by 10' do
        projects = @projects_overview.projects_datatable
        expect(projects.length).to eq 10
        expect(projects.uniq.length).to eq projects.length
        expect(projects).not_to include(project_2, project_4, project_5,
                                        project_6)
        projects1 = projects.reject(&:archived?)
                            .select(&:visible?)
        expect(projects1.length).to eq 10
      end
    end

    context "with request parameters { filter: 'active' }" do
      let(:params) { super().merge(filter: 'active') }

      it 'returns active projects, sorted by ascending archivation ' \
         'attribute (active first), offset by 0, paginated by 10' do
        projects = @projects_overview.projects_datatable
        expect(projects.length).to eq 10
        expect(projects.uniq.length).to eq projects.length
        expect(projects).not_to include(project_2, project_4, project_5,
                                        project_6)
        projects1 = projects.reject(&:archived?)
                            .select(&:visible?)
        expect(projects1.length).to eq 10
      end

      context 'with request parameters { start: 15 }' do
        let(:params) { super().merge(start: 15) }

        it 'returns active projects, sorted by ascending archivation ' \
           'attribute (active first), offset by 15, paginated by 10' do
          projects = @projects_overview.projects_datatable
          expect(projects.length).to eq 2
          expect(projects.uniq.length).to eq projects.length
          expect(projects).not_to include(project_1, project_2, project_3,
                                          project_4, project_5, project_6)
          projects1 = projects.reject(&:archived?)
                              .select(&:visible?)
          expect(projects1.length).to eq 2
        end
      end

      context 'with request parameters { length: 5 }' do
        let(:params) { super().merge(length: 5) }

        it 'returns active projects, sorted by ascending archivation ' \
           'attribute (active first), offset by 0, paginated by 5' do
          projects = @projects_overview.projects_datatable
          expect(projects.length).to eq 5
          expect(projects.uniq.length).to eq projects.length
          expect(projects).not_to include(project_2, project_4, project_5,
                                          project_6)
          projects1 = projects.reject(&:archived?)
                              .select(&:visible?)
          expect(projects1.length).to eq 5
        end
      end

      context "with request parameters { order: { '0': { dir: 'asc' } } }" do
        let(:params) { super().merge(order: { '0': { dir: 'asc' } }) }

        it 'returns active projects, sorted by ascending archivation ' \
           'attribute (archived first), offset by 0, paginated by 10' do
          projects = @projects_overview.projects_datatable
          expect(projects.length).to eq 10
          expect(projects.uniq.length).to eq projects.length
          expect(projects).not_to include(project_2, project_4, project_5,
                                          project_6)
          projects1 = projects.reject(&:archived?)
                              .select(&:visible?)
          expect(projects1.length).to eq 10
        end
      end

      context "with request parameters { order: { '0': { dir: 'desc' } } }" do
        let(:params) { super().merge(order: { '0': { dir: 'desc' } }) }

        it 'returns active projects, sorted by descending ' \
           'archivation attribute (archived first), offset by 0, ' \
           'paginated by 10' do
          projects = @projects_overview.projects_datatable
          expect(projects.length).to eq 10
          expect(projects.uniq.length).to eq projects.length
          expect(projects).not_to include(project_2, project_4, project_5,
                                          project_6)
          projects1 = projects.reject(&:archived?)
                              .select(&:visible?)
          expect(projects1.length).to eq 10
        end
      end

      context 'with request parameters { start: 13, length: 4 }' do
        let(:params) { super().merge(start: 13, length: 4) }

        it 'returns active projects, sorted by ascending archivation ' \
           'attribute (active first), offset by 13, paginated by 4' do
          projects = @projects_overview.projects_datatable
          expect(projects.length).to eq 0
          expect(projects).not_to include(project_1, project_2, project_3,
                                          project_4, project_5, project_6)
          projects1 = projects.reject(&:archived?)
                              .select(&:visible?)
          expect(projects1.length).to eq 0
        end
      end

      context "with request parameters { start: 1, length: 2, " \
              "order: { '0': { dir: 'asc', column: '2' } } }" do
        let(:params) do
          super().merge(start: 1, length: 2,
                        order: { '0': { dir: 'asc', column: '2' } })
        end

        it 'returns archived projects, sorted by ascending name ' \
           'attribute, offset by 1, paginated by 2' do
          projects = @projects_overview.projects_datatable
          expect(projects.length).to eq 2
          expect(projects).to eq [project_3, project_1]
        end
      end

      context "with request parameters { start: 3, length: 12, " \
              "order: { '0': { dir: 'desc', column: '2' } } }" do
        let(:params) do
          super().merge(start: 3, length: 12,
                        order: { '0': { dir: 'desc', column: '2' } })
        end

        it 'returns archived projects, sorted by descending name ' \
           'attribute, offset by 3, paginated by 12' do
          projects = @projects_overview.projects_datatable
          expect(projects.length).to eq 12
          expect(projects.uniq.length).to eq projects.length
          expect(projects).to eq [project_26, project_24, project_22,
                                  project_20, project_18, project_16,
                                  project_14, project_12, project_10,
                                  project_8, project_1, project_3]
          projects1 = projects.reject(&:archived?)
                              .select(&:visible?)
          expect(projects1.length).to eq 12
        end
      end
    end

    context "with request parameters { filter: 'archived' }" do
      let(:params) { super().merge(filter: 'archived') }

      it 'returns archived projects, sorted by ascending archivation ' \
         'attribute (archived first), offset by 0, paginated by 10' do
        projects = @projects_overview.projects_datatable
        expect(projects.length).to eq 10
        expect(projects.uniq.length).to eq projects.length
        expect(projects).not_to include(project_1, project_3, project_6)
        projects1 = projects.select(&:archived?)
                            .select(&:visible?)
        expect(projects1.length).to eq 10
      end

      context 'with request parameters { start: 15 }' do
        let(:params) { super().merge(start: 15) }

        it 'returns archived projects, sorted by ascending archivation ' \
           'attribute (archived first), offset by 15, paginated by 10' do
          projects = @projects_overview.projects_datatable
          expect(projects.length).to eq 3
          expect(projects.uniq.length).to eq projects.length
          expect(projects).not_to include(project_1, project_2, project_3,
                                          project_4, project_5, project_6)
          projects1 = projects.select(&:archived?)
                              .select(&:visible?)
          expect(projects1.length).to eq 3
        end
      end

      context 'with request parameters { length: 5 }' do
        let(:params) { super().merge(length: 5) }

        it 'returns archived projects, sorted by ascending archivation ' \
           'attribute (archived first), offset by 0, paginated by 5' do
          projects = @projects_overview.projects_datatable
          expect(projects.length).to eq 5
          expect(projects.uniq.length).to eq projects.length
          expect(projects).not_to include(project_1, project_3, project_6)
          projects1 = projects.select(&:archived?)
                              .select(&:visible?)
          expect(projects1.length).to eq 5
        end
      end

      context "with request parameters { order: { '0': { dir: 'asc' } } }" do
        let(:params) { super().merge(order: { '0': { dir: 'asc' } }) }

        it 'returns archived projects, sorted by ascending archivation ' \
           'attribute (archived first), offset by 0, paginated by 10' do
          projects = @projects_overview.projects_datatable
          expect(projects.length).to eq 10
          expect(projects.uniq.length).to eq projects.length
          expect(projects).not_to include(project_1, project_3, project_6)
          projects1 = projects.select(&:archived?)
                              .select(&:visible?)
          expect(projects1.length).to eq 10
        end
      end

      context "with request parameters { order: { '0': { dir: 'desc' } } }" do
        let(:params) { super().merge(order: { '0': { dir: 'desc' } }) }

        it 'returns archived projects, sorted by descending ' \
           'archivation attribute (archived first), offset by 0, paginated by' \
           '10' do
          projects = @projects_overview.projects_datatable
          expect(projects.length).to eq 10
          expect(projects.uniq.length).to eq projects.length
          expect(projects).not_to include(project_1, project_3, project_6)
          projects1 = projects.select(&:archived?)
                              .select(&:visible?)
          expect(projects1.length).to eq 10
        end
      end

      context 'with request parameters { start: 13, length: 4 }' do
        let(:params) { super().merge(start: 13, length: 4) }

        it 'returns archived projects, sorted by ascending archivation ' \
           'attribute (archived first), offset by 13, paginated by 4' do
          projects = @projects_overview.projects_datatable
          expect(projects.length).to eq 1
          expect(projects).not_to include(project_1, project_2, project_3,
                                          project_4, project_5, project_6)
          projects1 = projects.select(&:archived?)
                              .select(&:visible?)
          expect(projects1.length).to eq 1
        end
      end

      context "with request parameters { start: 7, length: 6, " \
              "order: { '0': { dir: 'desc', column: '3' } } }" do
        let(:params) do
          super().merge(start: 7, length: 6,
                        order: { '0': { dir: 'desc', column: '3' } })
        end

        it 'returns archived projects, sorted by descending creation ' \
           'time attribute, offset by 7, paginated by 6' do
          projects = @projects_overview.projects_datatable
          expect(projects.length).to eq 6
          expect(projects.uniq.length).to eq projects.length
          expect(projects).to eq [project_13, project_11, project_9,
                                  project_7, project_5, project_4]
          projects1 = projects.select(&:archived?)
                              .select(&:visible?)
          expect(projects1.length).to eq 6
        end
      end
    end
  end
end
