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
      modules = (params[:modules].select { |_, p| p == '1' })
                .keys
                .collect(&:to_i)

      # Get unique experiments from given modules
      experiments = MyModule.where(id: modules).map(&:experiment).uniq
      experiments.each do |experiment|
        res << generate_new_el(false)
        el = generate_el(
          'reports/elements/experiment_element.html.erb',
          experiment: experiment
        )
        el[:children] = generate_experiment_contents_json(experiment, modules)
        res << el
      end
    end
    res << generate_new_el(false)
    res
  end

  def generate_experiment_contents_json(experiment, selected_modules)
    res = []
    experiment.my_modules.each do |my_module|
      next unless selected_modules.include?(my_module.id)

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
      protocol = contents.element == :step ? my_module.protocol.present? : true
      next unless in_params?("module_#{contents.element}".to_sym) && protocol
      res << generate_new_el(false)
      if contents.children
        contents.collection(my_module).each do |report_el|
          el = generate_el(
            "reports/elements/my_module_#{contents
                                          .element
                                          .to_s
                                          .singularize}_element.html.erb",
            contents.parse_locals([report_el])
          )
          if contents.locals.first == :step
            el[:children] = generate_step_contents_json(report_el)
          elsif contents.locals.first == :result
            el[:children] = generate_result_contents_json(report_el)
          end
          res << el
        end
      else
        file_name = contents.file_name
        file_name = contents.element if contents.element == :samples
        res << generate_el(
          "reports/elements/my_module_#{file_name}_element.html.erb",
          contents.parse_locals([my_module, :asc])
        )
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
          'reports/elements/step_checklist_element.html.erb',
          { checklist: checklist }
        )
      end
    end
    if in_params? :step_assets
      step.assets.each do |asset|
        res << generate_new_el(false)
        res << generate_el(
          'reports/elements/step_asset_element.html.erb',
          { asset: asset }
        )
      end
    end
    if in_params? :step_tables
      step.tables.each do |table|
        res << generate_new_el(false)
        res << generate_el(
          'reports/elements/step_table_element.html.erb',
          { table: table }
        )
      end
    end
    if in_params? :step_comments
      res << generate_new_el(false)
      res << generate_el(
        'reports/elements/step_comments_element.html.erb',
        { step: step, order: :asc }
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
        'reports/elements/result_comments_element.html.erb',
        { result: result, order: :asc }
      )
    else
      res << generate_new_el(false)
    end
    res
  end

  def elements_empty?(elements)
    return true if elements.blank? || elements.count == 0

    if elements.count == 1
      el = elements[0]
      return true if el.include?(:new_element) && el[:new_element]
      return false
    end
    false
  end
end
