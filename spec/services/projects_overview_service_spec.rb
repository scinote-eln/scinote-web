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
    before(:all) { @params = {} }

    context 'with no request parameters' do
      it 'returns all projects' do
        projects = projects_overview.project_cards(@params)
        expect(projects).to include(project_1, project_2, project_3, project_4,
                                    project_5, project_6)
        expect(projects.length).to eq PROJECTS_CNT
        expect(projects.uniq.length).to eq projects.length
      end
    end

    context do
      before(:all) { @params1 = @params.merge(filter: 'active') }

      context "with #{@params1} request parameters" do
        it 'returns all active projects' do
          projects = projects_overview.project_cards(@params1)
          expect(projects.length).to eq PROJECTS_CNT / 2
          expect(projects.uniq.length).to eq projects.length
          expect(projects).to include(project_1, project_3, project_6)
          expect(projects).not_to include(project_2, project_4, project_5)
        end

        context do
          before(:all) { @params2 = @params1.merge(sort: 'old') }

          context "with #{@params2} request parameters" do
            it 'returns all active projects, sorted by ascending creation ' \
               'time attribute' do
              projects = projects_overview.project_cards(@params2)
              expect(projects.length).to eq PROJECTS_CNT / 2
              expect(projects.uniq.length).to eq projects.length
              expect(projects.first(3)).to eq [project_1, project_3, project_6]
              expect(projects).not_to include(project_2, project_4, project_5)
            end
          end
        end

        context do
          before(:all) { @params2 = @params1.merge(sort: 'new') }

          context "with #{@params2} request parameters" do
            it 'returns all active projects, sorted by descending creation ' \
               'time attribute' do

              projects = projects_overview.project_cards(@params2)
              expect(projects.length).to eq PROJECTS_CNT / 2
              expect(projects.uniq.length).to eq projects.length
              expect(projects.last(3)).to eq [project_6, project_3, project_1]
              expect(projects).not_to include(project_2, project_4, project_5)
            end
          end
        end

        context do
          before(:all) { @params2 = @params1.merge(sort: 'atoz') }

          context "with #{@params2} request parameters" do
            it 'returns all active projects, sorted by ascending name ' \
               'attribute' do
              projects = projects_overview.project_cards(@params2)
              expect(projects.length).to eq PROJECTS_CNT / 2
              expect(projects.uniq.length).to eq projects.length
              expect(projects.first(3)).to eq [project_3, project_1, project_6]
              expect(projects).not_to include(project_2, project_4, project_5)
            end
          end
        end

        context do
          before(:all) { @params2 = @params1.merge(sort: 'ztoa') }

          context "with #{@params2} request parameters" do
            it 'returns all active projects, sorted by descending name ' \
               ' attribute' do
              projects = projects_overview.project_cards(@params2)
              expect(projects.length).to eq PROJECTS_CNT / 2
              expect(projects.uniq.length).to eq projects.length
              expect(projects.last(3)).to eq [project_6, project_1, project_3]
              expect(projects).not_to include(project_2, project_4, project_5)
            end
          end
        end
      end
    end

    context do
      before(:all) { @params1 = @params.merge(filter: 'archived') }

      context "with #{@params1} request parameters" do
        it 'returns all archived projects' do
          projects = projects_overview.project_cards(@params1)
          expect(projects.length).to eq PROJECTS_CNT / 2
          expect(projects.uniq.length).to eq projects.length
          expect(projects).to include(project_2, project_4, project_5)
          expect(projects).not_to include(project_1, project_3, project_6)
        end

        context do
          before(:all) { @params2 = @params1.merge(sort: 'old') }

          context "with #{@params2} request parameters" do
            it 'returns all archived projects, sorted by ascending creation ' \
               'time attribute' do
              projects = projects_overview.project_cards(@params2)
              expect(projects.length).to eq PROJECTS_CNT / 2
              expect(projects.uniq.length).to eq projects.length
              expect(projects.first(3)).to eq [project_2, project_4, project_5]
              expect(projects).not_to include(project_1, project_3, project_6)
            end
          end
        end

        context do
          before(:all) { @params2 = @params1.merge(sort: 'new') }

          context "with #{@params2} request parameters" do
            it 'returns all archived projects, sorted by descending creation ' \
               'time attribute' do
              projects = projects_overview.project_cards(@params2)
              expect(projects.length).to eq PROJECTS_CNT / 2
              expect(projects.uniq.length).to eq projects.length
              expect(projects.last(3)).to eq [project_5, project_4, project_2]
              expect(projects).not_to include(project_1, project_3, project_6)
            end
          end
        end

        context do
          before(:all) { @params2 = @params1.merge(sort: 'atoz') }

          context "with #{@params2} request parameters" do
            it 'returns all archived projects, sorted by ascending name ' \
               ' attribute' do
              projects = projects_overview.project_cards(@params2)
              expect(projects.length).to eq PROJECTS_CNT / 2
              expect(projects.uniq.length).to eq projects.length
              expect(projects.first(3)).to eq [project_4, project_2, project_5]
              expect(projects).not_to include(project_1, project_3, project_6)
            end
          end
        end

        context do
          before(:all) { @params2 = @params1.merge(sort: 'ztoa') }

          context "with #{@params2} request parameters" do
            it 'returns all archived projects, sorted by descending name ' \
               ' attribute' do
              projects = projects_overview.project_cards(@params2)
              expect(projects.length).to eq PROJECTS_CNT / 2
              expect(projects.uniq.length).to eq projects.length
              expect(projects.last(3)).to eq [project_5, project_2, project_4]
              expect(projects).not_to include(project_1, project_3, project_6)
            end
          end
        end
      end
    end
  end



  describe '#projects_datatable' do
    before(:all) { @params = {} }

    context 'with no request parameters' do
      it 'returns projects, sorted by ascending archivation attribute (active' \
         ' first), offset by 0, paginated by 10' do
        projects = projects_overview.projects_datatable(@params)
        expect(projects.length).to eq 10
        expect(projects.uniq.length).to eq projects.length
        expect(projects).not_to include(project_2, project_4, project_5)
        projects1 = projects.reject(&:archived?)
        expect(projects1.length).to eq 10
      end
    end

    context do
      before(:all) { @params1 = @params.merge(filter: 'active') }

      context "with #{@params1} request parameters" do
        it 'returns active projects, sorted by ascending archivation ' \
           'attribute (active first), offset by 0, paginated by 10' do
          projects = projects_overview.projects_datatable(@params1)
          expect(projects.length).to eq 10
          expect(projects.uniq.length).to eq projects.length
          expect(projects).not_to include(project_2, project_4, project_5)
          projects1 = projects.reject(&:archived?)
          expect(projects1.length).to eq 10
        end

        context do
          before(:all) { @params2 = @params1.merge(start: 15) }

          context "with #{@params2} request parameters" do
            it 'returns active projects, sorted by ascending archivation ' \
               'attribute (active first), offset by 15, paginated by 10' do
              projects = projects_overview.projects_datatable(@params2)
              expect(projects.length).to eq 3
              expect(projects.uniq.length).to eq projects.length
              expect(projects).not_to include(project_1, project_2, project_3,
                                              project_4, project_5, project_6)
              projects1 = projects.reject(&:archived?)
              expect(projects1.length).to eq 3
            end
          end
        end

        context do
          before(:all) { @params2 = @params1.merge(length: 5) }

          context "with #{@params2} request parameters" do
            it 'returns active projects, sorted by ascending archivation ' \
               'attribute (active first), offset by 0, paginated by 5' do
              projects = projects_overview.projects_datatable(@params2)
              expect(projects.length).to eq 5
              expect(projects.uniq.length).to eq projects.length
              expect(projects).not_to include(project_2, project_4, project_5)
              projects1 = projects.reject(&:archived?)
              expect(projects1.length).to eq 5
            end
          end
        end

        context do
          before(:all) { @params2 = @params1.merge(start: 13, length: 4) }

          context "with #{@params2} request parameters" do
            it 'returns active projects, sorted by ascending archivation ' \
               'attribute (active first), offset by 13, paginated by 4' do
              projects = projects_overview.projects_datatable(@params2)
              expect(projects.length).to eq 1
              expect(projects).not_to include(project_1, project_2, project_3,
                                              project_4, project_5, project_6)
              projects1 = projects.reject(&:archived?)
              expect(projects1.length).to eq 1
            end
          end
        end
      end

      context do
        before(:all) { @params1 = @params.merge(filter: 'archived') }

        context "with #{@params1} request parameters" do
          it 'returns archived projects, sorted by ascending archivation ' \
             'attribute (active first), offset by 0, paginated by 10' do
            projects = projects_overview.projects_datatable(@params1)
            expect(projects.length).to eq 10
            expect(projects.uniq.length).to eq projects.length
            expect(projects).not_to include(project_1, project_3, project_6)
            projects1 = projects.select(&:archived?)
            expect(projects1.length).to eq 10
          end

          context do
            before(:all) { @params2 = @params1.merge(start: 15) }

            context "with #{@params2} request parameters" do
              it 'returns archived projects, sorted by ascending archivation ' \
                 'attribute (active first), offset by 15, paginated by 10' do
                projects = projects_overview.projects_datatable(@params2)
                expect(projects.length).to eq 3
                expect(projects.uniq.length).to eq projects.length
                expect(projects).not_to include(project_1, project_2, project_3,
                                                project_4, project_5, project_6)
                projects1 = projects.select(&:archived?)
                expect(projects1.length).to eq 3
              end
            end
          end

          context do
            before(:all) { @params2 = @params1.merge(length: 5) }

            context "with #{@params2} request parameters" do
              it 'returns archived projects, sorted by ascending archivation ' \
                 'attribute (active first), offset by 0, paginated by 5' do
                projects = projects_overview.projects_datatable(@params2)
                expect(projects.length).to eq 5
                expect(projects.uniq.length).to eq projects.length
                expect(projects).not_to include(project_1, project_3, project_6)
                projects1 = projects.select(&:archived?)
                expect(projects1.length).to eq 5
              end
            end
          end

          context do
            before(:all) { @params2 = @params1.merge(start: 13, length: 4) }

            context "with #{@params2} request parameters" do
              it 'returns archived projects, sorted by ascending archivation ' \
                 'attribute (active first), offset by 13, paginated by 4' do
                projects = projects_overview.projects_datatable(@params2)
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
    end
  end
end
