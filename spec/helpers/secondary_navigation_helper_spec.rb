# frozen_string_literal: true

require 'rails_helper'

describe SecondaryNavigationHelper, type: :helper do
  def stub_request_names(controller:, action:)
    allow(helper).to receive(:controller_name).and_return(controller)
    allow(helper).to receive(:action_name).and_return(action)
  end

  describe 'action based predicates' do
    it 'matches the project and all projects pages by action' do
      stub_request_names(controller: 'projects', action: 'index')
      expect(helper.is_all_projects_index?).to be true
      expect(helper.is_all_projects_archive?).to be false

      stub_request_names(controller: 'projects', action: 'archive')
      expect(helper.is_all_projects_index?).to be false
      expect(helper.is_all_projects_archive?).to be true
    end

    it 'matches show for project info, project show and module info' do
      stub_request_names(controller: 'projects', action: 'show')
      expect(helper.is_project_info?).to be true
      expect(helper.is_project_show?).to be true
      expect(helper.is_module_info?).to be true

      stub_request_names(controller: 'projects', action: 'index')
      expect(helper.is_project_info?).to be false
    end

    it 'matches archive pages for projects, experiments and modules' do
      stub_request_names(controller: 'projects', action: 'experiment_archive')
      expect(helper.is_project_archive?).to be true

      stub_request_names(controller: 'experiments', action: 'module_archive')
      expect(helper.is_experiment_archive?).to be true

      stub_request_names(controller: 'my_modules', action: 'archive')
      expect(helper.is_module_archive?).to be true
    end

    it 'matches the experiment canvas page' do
      stub_request_names(controller: 'experiments', action: 'canvas')
      expect(helper.is_experiment_canvas?).to be true

      stub_request_names(controller: 'experiments', action: 'show')
      expect(helper.is_experiment_canvas?).to be false
    end

    it 'matches the protocol pages of a module' do
      stub_request_names(controller: 'protocols', action: 'protocols')
      expect(helper.is_module_protocols?).to be true

      stub_request_names(controller: 'protocols', action: 'protocol_show')
      expect(helper.is_module_protocols?).to be true

      stub_request_names(controller: 'protocols', action: 'steps')
      expect(helper.is_module_protocols?).to be false
    end

    it 'matches the activities and steps pages' do
      stub_request_names(controller: 'my_modules', action: 'activities')
      expect(helper.is_module_activities?).to be true

      stub_request_names(controller: 'my_modules', action: 'steps')
      expect(helper.is_module_activities?).to be false
    end
  end

  describe 'controller and action based predicates' do
    it 'matches module results for the results index and the results show page' do
      stub_request_names(controller: 'results', action: 'index')
      expect(helper.is_module_results?).to be true

      stub_request_names(controller: 'my_modules', action: 'results_show')
      expect(helper.is_module_results?).to be true

      stub_request_names(controller: 'projects', action: 'index')
      expect(helper.is_module_results?).to be false
    end

    it 'matches the assigned items and module reports pages' do
      stub_request_names(controller: 'my_module_repositories', action: 'index')
      expect(helper.is_module_assigned_items?).to be true

      stub_request_names(controller: 'my_module_reports', action: 'index')
      expect(helper.is_module_reports?).to be true
      expect(helper.is_module_assigned_items?).to be false
    end

    it 'matches the reports index for project reports only' do
      stub_request_names(controller: 'reports', action: 'index')
      expect(helper.is_project_reports?).to be true

      stub_request_names(controller: 'my_module_reports', action: 'index')
      expect(helper.is_project_reports?).to be false
    end
  end

  describe '#title_element' do
    it 'returns the current team on the all projects page' do
      team = double('Team')
      allow(helper).to receive(:all_projects_page?).and_return(true)
      without_partial_double_verification { allow(helper).to receive(:current_team).and_return(team) }

      expect(helper.title_element).to eq team
    end

    it 'returns the project when on a project page' do
      project = double('Project')
      allow(helper).to receive(:all_projects_page?).and_return(false)
      allow(helper).to receive(:project_page?).and_return(true)
      helper.instance_variable_set(:@project, project)

      expect(helper.title_element).to eq project
    end

    it 'returns the experiment when on an experiment page' do
      experiment = double('Experiment')
      allow(helper).to receive(:all_projects_page?).and_return(false)
      allow(helper).to receive(:project_page?).and_return(false)
      allow(helper).to receive(:experiment_page?).and_return(true)
      helper.instance_variable_set(:@experiment, experiment)

      expect(helper.title_element).to eq experiment
    end

    it 'returns the module when on a module page' do
      my_module = double('MyModule')
      allow(helper).to receive(:all_projects_page?).and_return(false)
      allow(helper).to receive(:project_page?).and_return(false)
      allow(helper).to receive(:experiment_page?).and_return(false)
      allow(helper).to receive(:module_page?).and_return(true)
      helper.instance_variable_set(:@my_module, my_module)

      expect(helper.title_element).to eq my_module
    end

    it 'returns nil outside of the navigation pages' do
      allow(helper).to receive(:all_projects_page?).and_return(false)
      allow(helper).to receive(:project_page?).and_return(false)
      allow(helper).to receive(:experiment_page?).and_return(false)
      allow(helper).to receive(:module_page?).and_return(false)

      expect(helper.title_element).to be_nil
    end
  end
end
