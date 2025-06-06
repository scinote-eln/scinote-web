# frozen_string_literal: true

module ReportsHelper
  include StringUtility
  include Canaid::Helpers::PermissionsHelper

  def render_report_element(element, provided_locals = nil)
    case element.type_of
    when 'experiment'
      return unless can_read_experiment?(element.experiment)
    when 'my_module'
      return unless can_read_my_module?(element.my_module)
    end

    # Determine partial
    view = "reports/elements/#{element.type_of}_element"

    # Set locals
    locals = provided_locals.nil? ? {} : provided_locals.clone

    children_html = ''.html_safe
    # First, recursively render element's children
    if element.children.active.present?
      element.children.active.find_each do |child|
        children_html.safe_concat render_report_element(child, provided_locals)
      end
    end
    locals[:report_element] = element
    locals[:children] = children_html

    render partial: view, locals: locals, formats: :html
  end

  # "Hack" to omit file preview URL because of WKHTML issues
  def report_image_asset_url(asset)
    preview = asset.inline? ? asset.large_preview : asset.medium_preview
    image_tag(preview.processed.url(expires_in: Constants::URL_LONG_EXPIRE_TIME))
  rescue ActiveStorage::FileNotFoundError
    image_tag('icon_small/missing.svg')
  rescue StandardError => e
    Rails.logger.error e.message
    tag.i(I18n.t('projects.reports.index.generation.file_preview_generation_error'))
  end

  def assigned_repository_or_snapshot(my_module, repository)
    if repository.is_a?(RepositorySnapshot)
      return my_module.repository_snapshots.find_by(parent_id: repository.parent_id, selected: true)
    end

    return nil unless my_module.assigned_repositories.exists?(id: repository.id)

    selected_snapshot = repository.repository_snapshots.find_by(my_module: my_module, selected: true)
    selected_snapshot || repository
  end

  def step_status_label(step)
    if step.completed
      style = 'success'
      text = t('protocols.steps.completed')
    else
      style = 'default'
      text = t('protocols.steps.uncompleted')
    end
    "<span class=\"label step-label-#{style}\">[#{text}]</span>".html_safe
  end

  def filter_steps_for_report(steps, settings)
    include_completed_steps = settings.dig('task', 'protocol', 'completed_steps')
    include_uncompleted_steps = settings.dig('task', 'protocol', 'uncompleted_steps')
    if include_completed_steps && include_uncompleted_steps
      steps
    elsif include_completed_steps
      steps.where(completed: true)
    elsif include_uncompleted_steps
      steps.where(completed: false)
    else
      steps.none
    end
  end

  def order_results_for_report(results, order)
    case order
    when 'atoz'
      results.order(name: :asc)
    when 'ztoa'
      results.order(name: :desc)
    when 'new'
      results.order(created_at: :desc)
    when 'old_updated'
      results.order(updated_at: :asc)
    when 'new_updated'
      results.order(updated_at: :desc)
    else
      results.order(created_at: :asc)
    end
  end

  def report_experiment_descriptions(report)
    report.report_elements.experiment.map do |experiment_element|
      experiment_element.experiment.description
    end
  end

  def permit_report_settings_structure(settings_definition, repositories)
    settings_definition.each_with_object([]) do |(key, value), permitted|
      permitted << if key == :excluded_repository_columns && repositories.present?
                     { key => repositories.each_with_object({}) { |repository, hash| hash[repository.id.to_s] = [] } }
                   else
                     case value
                     when Hash
                       { key => permit_report_settings_structure(value, repositories) }
                     when Array
                       { key => [] }
                     else
                       key
                     end
                   end
    end
  end

  def custom_templates(templates)
    templates.any? { |template, _| template != :scinote_template }
  end

  def report_form_response_content(form_response)
    form_field_values = form_response.form_field_values

    form_response.form.form_fields&.map do |form_field|
      form_field_value = form_field_values.find_by(form_field_id: form_field.id, latest: true)

      value = if form_field_value&.not_applicable
                I18n.t('forms.export.values.not_applicable')
              elsif form_field_value.is_a?(FormTextFieldValue)
                custom_auto_link(
                  form_field_value&.formatted,
                  simple_format: false,
                  tags: %w(img),
                  team: current_team
                )
              elsif form_field_value.is_a?(FormDatetimeFieldValue)
                form_field_value&.formatted_localize
              else
                form_field_value&.formatted
              end

      {
        name: form_field.name,
        value: value,
        submitted_at: form_field_value&.submitted_at ? I18n.l(form_field_value&.submitted_at, format: :full) : '',
        submitted_by: form_field_value&.submitted_by&.full_name.to_s
      }
    end
  end
end
