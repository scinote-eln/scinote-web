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
      element.children.active.each do |child|
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

  def font_awesome_links
    [{ url: 'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.9.0/css/fontawesome.min.css' },
     { url: 'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.9.0/css/regular.min.css' },
     { url: 'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.9.0/css/solid.min.css' }]
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

  def assigned_to_report_repository_items(report, repository_name)
    repository = Repository.accessible_by_teams(report.team).where(name: repository_name).take
    return RepositoryRow.none if repository.blank?

    my_modules = MyModule.joins(:experiment)
                         .where(experiment: { project: report.project })
                         .where(id: report.report_elements.my_module.select(:my_module_id))
    repository.repository_rows.joins(:my_modules).where(my_modules: my_modules)
  end
end
