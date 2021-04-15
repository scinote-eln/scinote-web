# frozen_string_literal: true

module ReportActions
  class ReportContent
    include Canaid::Helpers::PermissionsHelper

    MY_MODULE_ADDITIONAL_ELEMENTS = ['my_module_activity']

    def initialize(content, setting, user)
      @content = content
      @setting = setting
      @user = user

    end

    def generate_content
      report_content = []
      @content.each do |_i, exp|
        report_content << generate_experiment_content(exp)
      end
      report_content
    end

    private

    def generate_experiment_content(exp)
      experiment = Experiment.find_by(id: exp[:experiment_id])
      return if !experiment && !can_read_experiment?(experiment, @user)

      children = []
      experiment.my_modules.where(id: exp[:my_modules]).each do |my_module|
        children << generate_my_module_content(my_module)
      end

      {
        'type_of' => 'experiment',
        'id' => { 'experiment_id' => experiment.id },
        'children' => children
      }
    end

    def generate_my_module_content(my_module)
      children = []
      protocol = my_module.protocols.first
      children << {
        'type_of' => 'my_module_protocol',
        'id' => { 'my_module_id' => my_module.id }
      }
      protocol.steps do |step|
        children << generate_step_content(step)
      end

      my_module.results do |result|
        children << generate_result_content(result)
      end

      MY_MODULE_ADDITIONAL_ELEMENTS.each do |e|
        children << {
          'type_of' => e,
          'id' => { 'my_module_id' => my_module.id }
        }
      end

      my_module.experiment.project.assigned_repositories_and_snapshots.each do |repository|
        children << {
          'type_of' => 'my_module_repository',
          'id' => {
            'repository_id' => repository.id,
            'my_module_id' => my_module.id
          }
        }
      end

      {
        'id' => { 'my_module_id' => my_module.id },
        'type_of' => 'my_module',
        'children' => children
      }
    end

    def generate_step_content(step)
      children = []

      step.step_checklists.each do |checklist|
        children << {
          'id' => { 'checklist_id' => checklist.id },
          'type_of' => 'step_checklist'
        }
      end

      step.step_tables.each do |table|
        children << {
          'id' => { 'table_id' => table.id },
          'type_of' => 'step_table'
        }
      end

      step.step_checklists.each do |asset|
        children << {
          'id' => { 'asset_id' => asset.id },
          'type_of' => 'step_asset'
        }
      end

      children << {
        'id' => { 'step_id' => step.id },
        'type_of' => 'step_comments'
      }

      {
        'id' => { 'step_id' => step.id },
        'type_of' => 'step',
        'children' => children
      }
    end

    def generate_result_content(result)
      {
        'type_of' => (result.result_asset || result.result_table || result.result_text).class.to_s.underscore,
        'id' => { 'result_id' => result.id },
        'children' => [{
          'id' => { 'result_id' => result.id },
          'type_of' => 'result_comments'
        }]
      }
    end
  end
end
