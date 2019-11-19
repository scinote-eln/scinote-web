# frozen_string_literal: true

module ReportActions
  extend ActiveSupport::Concern

  def in_params?(val)
    params.include? val and params[val] == '1'
  end

  def generate_new_el(hide)
    el = {}
    el[:html] = render_to_string(
      partial: 'reports/elements/new_element.html.erb',
      locals: { hide: hide }
    )
    el[:children] = []
    el[:new_element] = true
    el
  end

  def generate_el(partial, locals)
    el = {}
    el[:html] = render_to_string(
      partial: partial,
      locals: locals
    )
    el[:children] = []
    el[:new_element] = false
    el
  end

  def generate_project_contents_json
    res = []
    if params.include? :modules
      module_ids = (params[:modules].select { |_, p| p == '1' }).keys.collect(&:to_i)

      # Get unique experiments from given modules
      experiments = @project.experiments.distinct.joins(:my_modules).where('my_modules.id': module_ids)
      experiments.each do |experiment|
        res << generate_new_el(false)
        el = generate_el(
          'reports/elements/experiment_element.html.erb',
          experiment: experiment
        )
        selected_modules = experiment.my_modules.includes(:tags).where(id: module_ids)
        el[:children] = generate_experiment_contents_json(selected_modules)
        res << el
      end
    end
    res << generate_new_el(false)
    res
  end

  def generate_experiment_contents_json(selected_modules)
    res = []
    selected_modules.order(:workflow_order).each do |my_module|
      res << generate_new_el(false)
      el = generate_el(
        'reports/elements/my_module_element.html.erb',
        my_module: my_module
      )
      el[:children] = generate_module_contents_json(my_module)
      res << el
    end
    res << generate_new_el(false)
    res
  end

  def generate_module_contents_json(my_module)
    res = []

    ReportExtends::MODULE_CONTENTS.each do |contents|
      elements = []
      contents.values.each do |element|
        if contents.has_many
          elements = params.select { |k| k.starts_with?("module_#{element}") }
          elements = elements.select { |_, v| v == '1' }.keys
          elements.map! { |el| el.gsub('module_', '') }.map! { |el| el.split('_') }
          elements.map! { |el| [el[0].to_sym, el[1].to_i] }
          break unless elements.empty?
        else
          present = in_params?("module_#{element}".to_sym) || in_params?(element.to_sym)
          if present
            elements << [element.to_sym, nil]
            break
          end
        end
      end
      next if elements.empty?

      elements.each do |_, el_id|
        if contents.children
          contents.collection(my_module, params).each do |report_el|
            res << generate_new_el(false)
            locals = contents.parse_locals([report_el])
            locals[:element_id] = el_id if el_id
            el = generate_el(
              "reports/elements/my_module_#{contents.element.to_s.singularize}"\
              "_element.html.erb",
              locals
            )
            if :step.in? contents.locals
              el[:children] = generate_step_contents_json(report_el)
            elsif :result.in? contents.locals
              el[:children] = generate_result_contents_json(report_el)
            end
            res << el
          end
        else
          file_name = contents.file_name
          file_name = contents.element if contents.element == :samples
          res << generate_new_el(false)
          locals = contents.parse_locals([my_module, :asc])
          locals[:element_id] = el_id if el_id
          res << generate_el(
            "reports/elements/my_module_#{file_name}_element.html.erb",
            locals
          )
        end
      end
    end
    res << generate_new_el(false)
    res
  end

  def generate_step_contents_json(step)
    res = []
    if in_params? :step_checklists
      step.checklists.asc.each do |checklist|
        res << generate_new_el(false)
        res << generate_el(
          'reports/elements/step_checklist_element.html.erb', checklist: checklist
        )
      end
    end
    if in_params? :step_assets
      step.assets.each do |asset|
        res << generate_new_el(false)
        res << generate_el(
          'reports/elements/step_asset_element.html.erb', asset: asset
        )
      end
    end
    if in_params? :step_tables
      step.tables.each do |table|
        res << generate_new_el(false)
        res << generate_el(
          'reports/elements/step_table_element.html.erb', table: table
        )
      end
    end
    if in_params? :step_comments
      res << generate_new_el(false)
      res << generate_el(
        'reports/elements/step_comments_element.html.erb', step: step, order: :asc
      )
    end
    res << generate_new_el(false)
    res
  end

  def generate_result_contents_json(result)
    res = []
    if in_params? :result_comments
      res << generate_new_el(true)
      res << generate_el(
        'reports/elements/result_comments_element.html.erb', result: result, order: :asc
      )
    else
      res << generate_new_el(false)
    end
    res
  end

  def elements_empty?(elements)
    return true if elements.blank? || elements.count.zero?

    if elements.count == 1
      el = elements[0]
      return true if el.include?(:new_element) && el[:new_element]

      return false
    end
    false
  end
end
