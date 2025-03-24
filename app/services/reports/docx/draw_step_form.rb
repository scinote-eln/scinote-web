# frozen_string_literal: true

module Reports
  class Docx
    module DrawStepForm
      def draw_step_forms(element)
        return unless @settings.dig('task', 'protocol', 'step_forms')

        team = @report_team
        user = @user
        form_response = element.orderable
        color = @color
        form_fields = form_response.form.form_fields
        form_field_values = form_response.form_field_values

        table = [[
          I18n.t('projects.reports.elements.step_forms.field'),
          I18n.t('projects.reports.elements.step_forms.answer'),
          I18n.t('projects.reports.elements.step_forms.submitted_at'),
          I18n.t('projects.reports.elements.step_forms.submitted_by')
        ]]

        form_fields&.each do |form_field|
          form_field_value = form_field_values.find_by(form_field_id: form_field.id, latest: true)
          value = if form_field_value&.not_applicable
                    I18n.t('forms.export.values.not_applicable')
                  elsif form_field_value.is_a?(FormTextFieldValue)
                    SmartAnnotations::TagToText.new(user, team, form_field_value&.formatted).text
                  else
                    form_field_value&.formatted
                  end
          table << [
            form_field.name,
            value,
            form_field_value&.submitted_at&.utc.to_s,
            form_field_value&.submitted_by&.full_name.to_s
          ]
        end

        @docx.p
        @docx.table table, border_size: Constants::REPORT_DOCX_TABLE_BORDER_SIZE do
          cell_style rows[0], bold: true, background: color[:concrete]
        end

        @docx.p do
          text I18n.t('projects.reports.elements.step_forms.table_name', name: form_response.form.name), italic: true
          text ' '

          if form_response.submitted?
            text I18n.t('projects.reports.elements.step_forms.user_time', user: form_response.submitted_by&.full_name,
                                                                          timestamp: I18n.l(form_response.submitted_at, format: :full)), color: color[:gray]
          else
            text I18n.t('projects.reports.elements.step_forms.not_submitted'), color: color[:gray]
          end
        end
      end
    end
  end
end
