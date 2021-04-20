# frozen_string_literal: true

module ReportActions
  class ReportContent
    include Canaid::Helpers::PermissionsHelper

    MY_MODULE_ADDONS_ELEMENTS = []

    def initialize(report, content, template_values, user)
      @content = content
      @settings = report.settings
      @user = user
      @element_position = 0
      @report = report
      @template_values = template_values
    end

    def save_with_content
      Report.transaction do
        # Save the report itself
        @report.save!

        # Delete existing report elements
        @report.report_elements.destroy_all

        # Save new report elements
        generate_content

        # Delete existing template values
        @report.report_template_values.destroy_all

        formatted_template_values = @template_values.as_json.map { |k, v| v['name'] = k; v }
        # Save new template values
        @report.report_template_values.create!(formatted_template_values)
      end

      @report
    rescue ActiveRecord::ActiveRecordError, ArgumentError => e
      Rails.logger.error e.message
      raise ActiveRecord::Rollback
    end

    private

    def generate_content
      @content.each do |_i, exp|
        generate_experiment_content(exp)
      end
    end

    def generate_experiment_content(exp)
      experiment = Experiment.find_by(id: exp[:experiment_id])
      return if !experiment && !can_read_experiment?(experiment, @user)

      experiment_element = save_element({ 'experiment_id' => experiment.id }, :experiment, nil)
      generate_my_modules_content(experiment, experiment_element, exp[:my_modules])
    end

    def generate_my_modules_content(experiment, experiment_element, selected_my_modules)
      my_modules = experiment.my_modules
                             .active
                             .includes(:results, protocols: [:steps])
                             .where(id: selected_my_modules)
      my_modules.sort_by { |m| selected_my_modules.index m.id }.each do |my_module|
        my_module_element = save_element({ 'my_module_id' => my_module.id }, :my_module, experiment_element)

        if @settings.dig('task', 'protocol', 'description')
          save_element({ 'my_module_id' => my_module.id }, :my_module_protocol, my_module_element)
        end

        generate_steps_content(my_module, my_module_element)

        generate_results_content(my_module, my_module_element)

        if @settings.dig('task', 'activities')
          save_element({ 'my_module_id' => my_module.id }, :my_module_activity, my_module_element)

        end

        my_module.experiment.project.assigned_repositories_and_snapshots.each do |repository|
          save_element(
            { 'my_module_id' => my_module.id, 'repository_id' => repository.id },
            :my_module_repository,
            my_module_element
          )
        end

        MY_MODULE_ADDONS_ELEMENTS.each do |e|
          send("generate_#{e}_content", my_module, my_module_element)
        end
      end
    end

    def generate_steps_content(my_module, my_module_element)
      my_module.protocols.first.steps
               .includes(:checklists, :step_tables, :step_assets, :step_comments)
               .order(:position).each do |step|
        step_element = nil
        if step.completed && @settings.dig('task', 'protocol', 'completed_steps')
          step_element = save_element({ 'step_id' => step.id }, :step, my_module_element)
        elsif @settings.dig('task', 'protocol', 'uncompleted_steps')
          step_element = save_element({ 'step_id' => step.id }, :step, my_module_element)
        end

        next unless step_element

        if @settings.dig('task', 'protocol', 'step_checklists')
          step.checklists.each do |checklist|
            save_element({ 'checklist_id' => checklist.id }, :step_checklist, step_element)
          end
        end

        if @settings.dig('task', 'protocol', 'step_tables')
          step.step_tables.each do |table|
            save_element({ 'table_id' => table.id }, :step_table, step_element)
          end
        end

        if @settings.dig('task', 'protocol', 'step_files')
          step.step_assets.each do |asset|
            save_element({ 'asset_id' => asset.id }, :step_asset, step_element)
          end
        end

        if @settings.dig('task', 'protocol', 'step_comments')
          save_element({ 'step_id' => step.id }, :step_comments, step_element)
        end
      end
    end

    def generate_results_content(my_module, my_module_element)
      my_module.results do |result|
        result_type = (result.result_asset || result.result_table || result.result_text).class.to_s.underscore

        next unless @settings.dig('task', result_type)

        result_element = save_element({ 'result_id' => result.id }, result_type, my_module_element)

        save_element({ 'result_id' => result.id }, :result_comments, result_element)
      end
    end

    def save_element(reference, type_of, parent)
      el = ReportElement.new
      el.position = @element_position
      el.report = @report
      el.parent = parent
      el.type_of = type_of
      el.set_element_references(reference)
      el.save!

      @element_position += 1

      el
    end
  end
end
