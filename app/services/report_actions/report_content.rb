# frozen_string_literal: true

module ReportActions
  class ReportContent
    include Canaid::Helpers::PermissionsHelper

    MY_MODULE_ADDONS_ELEMENTS = []

    def initialize(content, settings, user)
      @content = content
      @settings = settings
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

      if @settings.dig('task', 'protocol', 'description')
        children << {
          'type_of' => 'my_module_protocol',
          'id' => { 'my_module_id' => my_module.id }
        }
      end

      protocol.steps do |step|
        if step.completed && @settings.dig('task', 'protocol', 'completed_steps')
          children << generate_step_content(step)
        elsif @settings.dig('task', 'protocol', 'uncompleted_steps')
          children << generate_step_content(step)
        end
      end

      my_module.results do |result|
        result_type = (result.result_asset || result.result_table || result.result_text).class.to_s.underscore
        next unless @settings.dig('task', result_type)

        children << generate_result_content(result, result_type)
      end

      if @settings.dig('task', 'activities')
        children << {
          'type_of' => 'my_module_activity',
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

      MY_MODULE_ADDONS_ELEMENTS.each do |e|
        children << send("generate_#{e}_content", my_module)
      end

      {
        'id' => { 'my_module_id' => my_module.id },
        'type_of' => 'my_module',
        'children' => children
      }
    end

    def generate_step_content(step)
      children = []

      if @settings.dig('task', 'protocol', 'step_checklists')
        step.step_checklists.each do |checklist|
          children << {
            'id' => { 'checklist_id' => checklist.id },
            'type_of' => 'step_checklist'
          }
        end
      end

      if @settings.dig('task', 'protocol', 'step_tables')
        step.step_tables.each do |table|
          children << {
            'id' => { 'table_id' => table.id },
            'type_of' => 'step_table'
          }
        end
      end

      if @settings.dig('task', 'protocol', 'step_files')
        step.step_assets.each do |asset|
          children << {
            'id' => { 'asset_id' => asset.id },
            'type_of' => 'step_asset'
          }
        end
      end

      if @settings.dig('task', 'protocol', 'step_comments')
        children << {
          'id' => { 'step_id' => step.id },
          'type_of' => 'step_comments'
        }
      end
      {
        'id' => { 'step_id' => step.id },
        'type_of' => 'step',
        'children' => children
      }
    end

    def generate_result_content(result, result_type)
      result = {
        'type_of' => result_type,
        'id' => { 'result_id' => result.id },
        'children' => []
      }

      if @settings.dig('task', 'result_comments')
        result.push({
                      'id' => { 'result_id' => result.id },
                      'type_of' => 'result_comments'
                    })
      end
      result
    end
  end
end
