# frozen_string_literal: true

require 'caxlsx'

class FormResponsesZipExportJob < ZipExportJob
  private

  # Override
  def fill_content(dir, params)
    form = Form.find_by(id: params[:form_id])

    exported_data = to_xlsx(form)

    File.binwrite("#{dir}/#{form.name}.xlsx", exported_data)
  end

  def failed_notification_title
    I18n.t('activejob.failure_notifiable_job.item_notification_title',
           item: I18n.t('activejob.failure_notifiable_job.items.form'))
  end

  def to_xlsx(form)
    package = Axlsx::Package.new
    workbook = package.workbook

    warning_bg_style = workbook.styles.add_style bg_color: 'ffbf00'

    workbook.add_worksheet(name: 'Form submissions') do |sheet|
      sheet.add_row build_header(form)
      form.form_responses.where(status: 'submitted').find_each do |form_response|
        sheet.add_row do |row|
          row.add_cell breadcrumbs(form_response)
          row.add_cell form_response.submitted_at.to_s
          row.add_cell form_response.submitted_by.full_name
          form_response.form_field_values.joins(:form_field).where(latest: true).order(:position).each do |form_field_value|
            if form_field_value.value_in_range?
              row.add_cell form_field_value.formatted
            else
              row.add_cell form_field_value.formatted, style: warning_bg_style
            end
            row.add_cell form_field_value.submitted_at.to_s
            row.add_cell form_field_value.submitted_by.full_name
          end
        end
      end
    end

    package.to_stream.read
  end

  def build_header(form)
    header = [I18n.t('forms.export.columns.form_path'), I18n.t('forms.export.columns.form_timestamp'), I18n.t('forms.export.columns.submitted_by')]
    form.form_fields.order(:position).select(:name).each do |form_field|
      header << form_field.name
      header << I18n.t('forms.export.columns.form_field_timestamp', name: form_field.name)
      header << I18n.t('forms.export.columns.form_field_submitted_by', name: form_field.name)
    end

    header
  end

  def breadcrumbs(form_response)
    return '' unless (my_module = form_response&.step&.my_module)

    [
      "#{my_module.project.name} (#{my_module.project.code})",
      "#{my_module.experiment.name} (#{my_module.experiment.code})",
      "#{my_module.name} (#{my_module.code})",
      my_module.protocol.name || I18n.t('search.index.untitled_protocol'),
      form_response.step.name || I18n.t('protocols.steps.default_name')
    ].join('/ ')
  end
end
