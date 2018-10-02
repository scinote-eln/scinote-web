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
      create :project, name: "extra test project #{(64 + i).chr}",
                       visibility: 1,
                       team: team, archived: i % 2,
                       created_at: time.advance(hours: 6, minutes: i)
    end
  end

  describe '#project_cards' do
    context 'with no parameters' do
      let(:params) do # klicaji?
        {} # don't use block if not needed
      end

      it 'returns all projects' do
        projects = projects_overview.project_cards(params)
        expect(projects).to include(project_1, project_2, project_3, project_4)
        expect(projects.length).to eq PROJECTS_CNT
      end
    end

    context "with 'active' parameter" do
      let(:params) { { filter: 'active' } }

      it 'returns all active projects' do
        projects = projects_overview.project_cards(params)
        expect(projects).to include(project_1, project_3, project_6)
        expect(projects.length).to eq PROJECTS_CNT / 2
      end

      context "with 'old' parameter" do
        let(:params) { super().merge(sort: 'old') }

        it 'returns all active projects in ascending creation order' do
          projects = projects_overview.project_cards(params)
          expect(projects.first(3)).to eq [project_1, project_3, project_6]
          expect(projects.length).to eq PROJECTS_CNT / 2
        end
      end

      context "with 'new' parameter" do
        let(:params) { super().merge(sort: 'new') }

        it 'returns all active projects in descending creation order' do
          projects = projects_overview.project_cards(params)
          expect(projects.length).to eq PROJECTS_CNT / 2
          some_projects = projects.select { |p| p.name.start_with? 'test' }
          expect(some_projects.first(3)).to eq [project_6, project_3, project_1]
        end
      end

      context "with 'atoz' parameter" do
        let(:params) { super().merge(sort: 'atoz') }

        it 'returns all active projects in ascending name order' do
          projects = projects_overview.project_cards(params)
          expect(projects.length).to eq PROJECTS_CNT / 2
          some_projects = projects.select { |p| p.name.start_with? 'test' }
          expect(some_projects.first(3)).to eq [project_3, project_1, project_6]
        end
      end

      context "with 'ztoa' parameter" do
        let(:params) { super().merge(sort: 'ztoa') }

        it 'returns all active projects in descending name order' do
          projects = projects_overview.project_cards(params)
          expect(projects.length).to eq PROJECTS_CNT / 2
          some_projects = projects.select { |p| p.name.start_with? 'test' }
          expect(some_projects.first(3)).to eq [project_6, project_1, project_3]
        end
      end
    end

    context "with 'archived' parameter" do
      let(:params) { { filter: 'archived' } }

      it 'returns all archived projects' do
        projects = projects_overview.project_cards(params)
        expect(projects.length).to eq PROJECTS_CNT / 2
        some_projects = projects.select { |p| p.name.start_with? 'test' }
        expect(some_projects).to include(project_2, project_4, project_5)
      end

      context "with 'old' parameter" do
        let(:params) { super().merge(sort: 'old') }

        it 'returns all archived projects in ascending creation order' do
          projects = projects_overview.project_cards(params)
          expect(projects.length).to eq PROJECTS_CNT / 2
          some_projects = projects.select { |p| p.name.start_with? 'test' }
          expect(some_projects.first(3)).to eq [project_2, project_4, project_5]
        end
      end

      context "with 'new' parameter" do
        let(:params) { super().merge(sort: 'new') }

        it 'returns all archived projects in descending creation order' do
          projects = projects_overview.project_cards(params)
          expect(projects.length).to eq PROJECTS_CNT / 2
          some_projects = projects.select { |p| p.name.start_with? 'test' }
          expect(some_projects.first(3)).to eq [project_5, project_4, project_2]
        end
      end

      context "with 'atoz' parameter" do
        let(:params) { super().merge(sort: 'atoz') }

        it 'returns all archived projects in ascending name order' do
          projects = projects_overview.project_cards(params)
          expect(projects.length).to eq PROJECTS_CNT / 2
          some_projects = projects.select { |p| p.name.start_with? 'test' }
          expect(some_projects.first(3)).to eq [project_4, project_2, project_5]
        end
      end

      context "with 'ztoa' parameter" do
        let(:params) { super().merge(sort: 'ztoa') }

        it 'returns all archived projects in descending name order' do
          projects = projects_overview.project_cards(params)
          expect(projects.length).to eq PROJECTS_CNT / 2
          some_projects = projects.select { |p| p.name.start_with? 'test' }
          expect(some_projects.first(3)).to eq [project_5, project_2, project_4]
        end
      end
    end
  end
end
