class ReportsController < ApplicationController
  # Ignore CSRF protection just for PDF generation (because it's
  # used via target='_blank')
  protect_from_forgery with: :exception, :except => :generate

  before_action :load_vars, only: [
    :edit,
    :update
  ]
  before_action :load_vars_nested, only: [
    :index,
    :new,
    :create,
    :edit,
    :update,
    :generate,
    :destroy,
    :save_modal,
    :project_contents_modal,
    :experiment_contents_modal,
    :module_contents_modal,
    :step_contents_modal,
    :result_contents_modal,
    :project_contents,
    :module_contents,
    :step_contents,
    :result_contents
  ]

  before_action :check_view_permissions, only: [:index]
  before_action :check_create_permissions, only: [
    :new,
    :create,
    :edit,
    :update,
    :generate,
    :save_modal,
    :project_contents_modal,
    :experiment_contents_modal,
    :module_contents_modal,
    :step_contents_modal,
    :result_contents_modal,
    :project_contents,
    :module_contents,
    :step_contents,
    :result_contents
  ]
  before_action :check_destroy_permissions, only: [:destroy]

  layout "fluid"

  # Initialize markdown parser
  def load_markdown
    @markdown = Redcarpet::Markdown.new(
      Redcarpet::Render::HTML.new(
        filter_html: true,
        no_images: true
      )
    )
  end

  # Index showing all reports of a single project
  def index
  end

  # Report grouped by modules
  def new
    @report = nil
  end

  # Creating new report from the _save modal of the new page
  def create
    continue = true
    begin
      report_contents = JSON.parse(params.delete(:report_contents))
    rescue
      continue = false
    end

    @report = Report.new(report_params)
    @report.project = @project
    @report.user = current_user
    @report.last_modified_by = current_user

    if continue and @report.save_with_contents(report_contents)
      respond_to do |format|
        format.json {
          render json: { url: project_reports_path(@project) }, status: :ok
        }
      end
    else
      respond_to do |format|
        format.json {
          render json: @report.errors, status: :unprocessable_entity
        }
      end
    end
  end

  def edit
    # cleans all the deleted report
    @report.cleanup_report
    load_markdown
    render "reports/new.html.erb"
  end

  # Updating existing report from the _save modal of the new page
  def update
    continue = true
    begin
      report_contents = JSON.parse(params.delete(:report_contents))
    rescue
      continue = false
    end

    @report.last_modified_by = current_user
    @report.assign_attributes(report_params)

    if continue and @report.save_with_contents(report_contents)
      respond_to do |format|
        format.json {
          render json: { url: project_reports_path(@project) }, status: :ok
        }
      end
    else
      respond_to do |format|
        format.json {
          render json: @report.errors, status: :unprocessable_entity
        }
      end
    end
  end

  # Destroy multiple entries action
  def destroy
    unless params.include? :report_ids
      render_404
    end

    begin
      report_ids = JSON.parse(params[:report_ids])
    rescue
      render_404
    end

    report_ids.each do |report_id|
      report = Report.find_by_id(report_id)

      if report.present?
        report.destroy
      end
    end

    redirect_to project_reports_path(@project)
  end

  # Generation action
  # Currently, only .PDF is supported
  def generate
    respond_to do |format|
      format.pdf {
        @html = params[:html]
        if @html.blank? then
          @html = "<h1>No content</h1>"
        end
        render pdf: "report",
          header: { right: '[page] of [topage]' },
          template: "reports/report.pdf.erb"
      }
    end
  end

  # Modal for saving the existsing/new report
  def save_modal
    # Assume user is updating existing report
    @report = Report.find_by_id(params[:id])
    @method = :put

    # Case when saving a new report
    if @report.blank?
      @report = Report.new
      @method = :post
      @url = project_reports_path(@project, format: :json)
    else
      @url = project_report_path(@project, @report, format: :json)
    end

    if !params.include? :contents
      render_403 and return
    end
    @report_contents = params[:contents]

    respond_to do |format|
      format.json {
        render json: {
          html: render_to_string({
            partial: "reports/new/modal/save.html.erb"
          })
        }
      }
    end
  end

  # Modal for adding contents into project element
  def project_contents_modal
    respond_to do |format|
      format.json {
        render json: {
          html: render_to_string({
            partial: "reports/new/modal/project_contents.html.erb",
            locals: { project: @project }
            })
        }
      }
    end
  end

  # Experiment for adding contents into experiment element
  def experiment_contents_modal
    experiment = Experiment.find_by_id(params[:id])

    respond_to do |format|
      if experiment.blank?
        format.json do
          render json: {}, status: :not_found
        end
      else
        format.json do
          render json: {
            html: render_to_string(
              partial: 'reports/new/modal/experiment_contents.html.erb',
              locals: { project: @project, experiment: experiment }
            )
          }
        end
      end
    end
  end

  # Modal for adding contents into module element
  def module_contents_modal
    my_module = MyModule.find_by_id(params[:id])

    respond_to do |format|
      if my_module.blank?
        format.json do
          render json: {}, status: :not_found
        end
      else
        format.json do
          render json: {
            html: render_to_string(
              partial: "reports/new/modal/module_contents.html.erb",
              locals: { project: @project, my_module: my_module }
            )
          }
        end
      end
    end
  end

  # Modal for adding contents into step element
  def step_contents_modal
    step = Step.find_by_id(params[:id])

    respond_to do |format|
      if step.blank?
        format.json {
          render json: {}, status: :not_found
        }
      else
        format.json {
          render json: {
            html: render_to_string({
              partial: "reports/new/modal/step_contents.html.erb",
              locals: { project: @project, step: step }
            })
          }
        }
      end
    end
  end

  # Modal for adding contents into result element
  def result_contents_modal
    result = Result.find_by_id(params[:id])

    respond_to do |format|
      if result.blank?
        format.json {
          render json: {}, status: :not_found
        }
      else
        format.json {
          render json: {
            html: render_to_string({
              partial: "reports/new/modal/result_contents.html.erb",
              locals: { project: @project, result: result }
            })
          }
        }
      end
    end
  end

  def project_contents
    respond_to do |format|
      elements = generate_project_contents_json

      if elements_empty? elements
        format.json { render json: {}, status: :no_content }
      else
        format.json {
          render json: {
            status: :ok,
            elements: elements
          }
        }
      end
    end
  end

  def experiment_contents
    experiment = Experiment.find_by_id(params[:id])
    modules = (params[:modules].select { |_, p| p == "1" })
              .keys
              .collect(&:to_i)

    respond_to do |format|
      if experiment.blank?
        format.json { render json: {}, status: :not_found }
      elsif modules.blank?
        format.json { render json: {}, status: :no_content }
      else
        elements = generate_experiment_contents_json(experiment, modules)
      end

      if elements_empty? elements
        format.json { render json: {}, status: :no_content }
      else
        format.json do
          render json: {
            status: :ok,
            elements: elements
          }
        end
      end
    end
  end

  def module_contents
    my_module = MyModule.find_by_id(params[:id])

    respond_to do |format|
      if my_module.blank?
        format.json { render json: {}, status: :not_found }
      else
        elements = generate_module_contents_json(my_module)

        if elements_empty? elements
          format.json { render json: {}, status: :no_content }
        else
          format.json {
            render json: {
              status: :ok,
              elements: elements
            }
          }
        end
      end
    end
  end

  def step_contents
    step = Step.find_by_id(params[:id])

    respond_to do |format|
      if step.blank?
        format.json { render json: {}, status: :not_found }
      else
        elements = generate_step_contents_json(step)

        if elements_empty? elements
          format.json { render json: {}, status: :no_content }
        else
          format.json {
            render json: {
              status: :ok,
              elements: elements
            }
          }
        end
      end
    end
  end

  def result_contents
    result = Result.find_by_id(params[:id])
    respond_to do |format|
      if result.blank?
        format.json { render json: {}, status: :not_found }
      else
        elements = generate_result_contents_json(result)

        if elements_empty? elements
          format.json { render json: {}, status: :no_content }
        else
          format.json {
            render json: {
              status: :ok,
              elements: elements
            }
          }
        end
      end
    end
  end

  private

  def in_params?(val)
    params.include? val and params[val] == "1"
  end

  def generate_new_el(hide)
    el = {}
    el[:html] = render_to_string({
        partial: "reports/elements/new_element.html.erb",
        locals: { hide: hide }
      })
    el[:children] = []
    el[:new_element] = true
    el
  end

  def generate_el(partial, locals)
    el = {}
    el[:html] = render_to_string({
      partial: partial,
      locals: locals
    })
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
    if (in_params? :module_steps) && my_module.protocol.present? then
      my_module.protocol.completed_steps.each do |step|
        res << generate_new_el(false)
        el = generate_el(
          "reports/elements/step_element.html.erb",
          { step: step }
        )
        el[:children] = generate_step_contents_json(step)
        res << el
      end
    end
    if in_params? :module_result_assets then
      (my_module.results.select { |r| r.is_asset && r.active? }).each do |result_asset|
        res << generate_new_el(false)
        el = generate_el(
          "reports/elements/result_asset_element.html.erb",
          { result: result_asset }
        )
        el[:children] = generate_result_contents_json(result_asset)
        res << el
      end
    end
    if in_params? :module_result_tables then
      (my_module.results.select { |r| r.is_table && r.active? }).each do |result_table|
        res << generate_new_el(false)
        el = generate_el(
          "reports/elements/result_table_element.html.erb",
          { result: result_table }
        )
        el[:children] = generate_result_contents_json(result_table)
        res << el
      end
    end
    if in_params? :module_result_texts then
      load_markdown
      (my_module.results.select { |r| r.is_text && r.active? }).each do |result_text|
        res << generate_new_el(false)
        el = generate_el(
          "reports/elements/result_text_element.html.erb",
          { result: result_text, markdown: @markdown }
        )
        el[:children] = generate_result_contents_json(result_text)
        res << el
      end
    end
    if in_params? :module_activity then
      res << generate_new_el(false)
      res << generate_el(
        "reports/elements/my_module_activity_element.html.erb",
        { my_module: my_module, order: :asc }
      )
    end
    if in_params? :module_samples then
      res << generate_new_el(false)
      res << generate_el(
        "reports/elements/my_module_samples_element.html.erb",
        { my_module: my_module, order: :asc }
      )
    end
    res << generate_new_el(false)
    res
  end

  def generate_step_contents_json(step)
    res = []
    if in_params? :step_checklists then
      step.checklists.each do |checklist|
        res << generate_new_el(false)
        res << generate_el(
          "reports/elements/step_checklist_element.html.erb",
          { checklist: checklist }
        )
      end
    end
    if in_params? :step_assets then
      step.assets.each do |asset|
        res << generate_new_el(false)
        res << generate_el(
          "reports/elements/step_asset_element.html.erb",
          { asset: asset }
        )
      end
    end
    if in_params? :step_tables then
      step.tables.each do |table|
        res << generate_new_el(false)
        res << generate_el(
          "reports/elements/step_table_element.html.erb",
          { table: table }
        )
      end
    end
    if in_params? :step_comments then
      res << generate_new_el(false)
      res << generate_el(
        "reports/elements/step_comments_element.html.erb",
        { step: step, order: :asc }
      )
    end
    res << generate_new_el(false)
    res
  end

  def generate_result_contents_json(result)
    res = []
    if in_params? :result_comments then
      res << generate_new_el(true)
      res << generate_el(
        "reports/elements/result_comments_element.html.erb",
        { result: result, order: :asc }
      )
    else
      res << generate_new_el(false)
    end
    res
  end

  def elements_empty?(elements)
    if elements.blank?
      return true
    elsif elements.count == 0 then
      return true
    elsif elements.count == 1
      el = elements[0]
      if el.include? :new_element and el[:new_element]
        return true
      else
        return false
      end
    end
    return false
  end

  def load_vars
    @report = Report.find_by_id(params[:id])

    unless @report
      render_404
    end
  end

  def load_vars_nested
    @project = Project.find_by_id(params[:project_id])

    unless @project
      render_404
    end
  end

  def check_view_permissions
    unless can_view_reports(@project)
      render_403
    end
  end

  def check_create_permissions
    unless can_create_new_report(@project)
      render_403
    end
  end

  def check_destroy_permissions
    unless can_delete_reports(@project)
      render_403
    end
  end

  def report_params
    params.require(:report).permit(:name, :description, :grouped_by, :report_contents)
  end

end
