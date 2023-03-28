# frozen_string_literal: true

module ReportActions
  class ReportContent
    include Canaid::Helpers::PermissionsHelper
    include ReportsHelper

    MY_MODULE_ADDONS_ELEMENTS = []

    def initialize(report, content, template_values, user)
      @content = content
      @settings = report.settings
      @user = user
      @element_position = 0
      @report = report
      @template_values = template_values
      @repositories = @settings.dig(:task, :repositories)
    end

    def save_with_content
      Report.transaction do
        # Save the report itself
        @report.save!

        # Delete existing report elements
        @report.report_elements.destroy_all

        # Save new report elements
        begin
          generate_content
        rescue StandardError => e
          @report.errors.add(:content_error, I18n.t('projects.reports.index.generation.content_generation_error'))
          Rails.logger.error e.message
          raise ActiveRecord::Rollback
        end

        # Delete existing template values
        @report.report_template_values.destroy_all

        if @template_values.present?
          formatted_template_values = @template_values.as_json.map { |k, v| v['name'] = k; v }
          formatted_template_values.each do |template_value|
            if template_value['view_component'] == 'DateInputComponent'
              template_value['value'] =
                Date.strptime(template_value['value'], I18n.backend.date_format.dup.gsub(/%-/, '%')).iso8601
            end
          end
          # Save new template values
          @report.report_template_values.create!(formatted_template_values)
        end
      rescue ActiveRecord::ActiveRecordError, ArgumentError => e
        Rails.logger.error e.message
        raise ActiveRecord::Rollback
      end
    end

    private

    def generate_content
      save_element!({ 'project_id' => @report.project_id }, :project_header, nil)

      @content['experiments'].each do |experiment|
        generate_experiment_content(experiment[:id], experiment[:my_module_ids])
      end
    end

    def generate_experiment_content(experiment_id, my_module_ids)
      experiment = Experiment.find_by(id: experiment_id)
      return unless experiment && can_read_experiment?(@user, experiment)

      experiment_element = save_element!({ 'experiment_id' => experiment.id }, :experiment, nil)
      generate_my_modules_content(experiment, experiment_element, my_module_ids)
    end

    def generate_my_modules_content(experiment, experiment_element, my_module_ids)
      my_modules = experiment.my_modules
                             .active
                             .where(id: my_module_ids)
      my_modules.sort_by { |m| my_module_ids.index m.id }.each do |my_module|
        next unless can_read_my_module?(@user, my_module)

        my_module_element = save_element!({ 'my_module_id' => my_module.id }, :my_module, experiment_element)

        my_module.live_and_snapshot_repositories_list.each do |repository|
          next unless @repositories.include?(repository.parent_id || repository.id)

          save_element!(
            { 'my_module_id' => my_module.id, 'repository_id' => repository.id },
            :my_module_repository,
            my_module_element
          )
        end
      end
    end

    def save_element!(references, type_of, parent)
      el = ReportElement.new
      el.position = @element_position
      el.report = @report
      el.parent = parent
      el.type_of = type_of
      el.assign_attributes(references)
      el.save!

      @element_position += 1

      el
    end
  end
end
