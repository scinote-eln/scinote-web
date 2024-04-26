class SearchController < ApplicationController
  include IconsHelper
  include ProjectFoldersHelper
  before_action :load_vars, only: :index

  def index
    respond_to do |format|
      format.html do
        redirect_to new_search_path unless @search_query
      end
      format.json do
        redirect_to new_search_path unless @search_query

        case params[:group]
        when 'projects'
          @project_search_count = fetch_cached_count(Project)
          search_projects
          paginate_records
          render json: @records.includes(:team, :project_folder),
                 each_serializer: GlobalSearch::ProjectSerializer,
                 meta: {
                  total: @search_count,
                  next_page: (@records.next_page if @records.respond_to?(:next_page)),
                }
        when 'project_folders'
          @project_folder_search_count = fetch_cached_count ProjectFolder
          search_project_folders
          paginate_records
          render json: @records.includes(:team, :parent_folder),
                 each_serializer: GlobalSearch::ProjectFolderSerializer,
                 meta: {
                   total: @search_count,
                   next_page: @records.try(:next_page)
                 }
          return
        when 'reports'
          @report_search_count = fetch_cached_count Report
          search_reports
          paginate_records
          render json: @records.includes(:team, :project, :user),
                 each_serializer: GlobalSearch::ReportSerializer,
                 meta: {
                   total: @search_count,
                   next_page: @records.try(:next_page)
                 }
          return
        when 'module_protocols'
          search_module_protocols
          paginate_records
          render json: @records.joins({ my_module: :experiment }, :team),
                 each_serializer: GlobalSearch::MyModuleProtocolSerializer,
                 meta: {
                   total: @search_count,
                   next_page: @records.try(:next_page)
                 }
          return
        when 'experiments'
          @experiment_search_count = fetch_cached_count Experiment
          search_experiments
          paginate_records
          render json: @records.includes(project: :team),
                 each_serializer: GlobalSearch::ExperimentSerializer,
                 meta: {
                   total: @search_count,
                   next_page: @records.try(:next_page)
                 }
          return
        when 'tasks'
          @module_search_count = fetch_cached_count MyModule
          search_modules
          paginate_records
          render json: @records.includes(experiment: { project: :team }),
                 each_serializer: GlobalSearch::MyModuleSerializer,
                 meta: {
                   total: @search_count,
                   next_page: @records.try(:next_page)
                 }
          return
        when 'results'
          @result_search_count = fetch_cached_count(Result)
          search_results
          paginate_records
          render json: @records.includes(my_module: { experiment: { project: :team } }),
                 each_serializer: GlobalSearch::ResultSerializer,
                 meta: {
                   total: @search_count,
                   next_page: @records.try(:next_page)
                 }
          return
        when 'protocols'
          search_protocols
          paginate_records

          render json: @records,
                 each_serializer: GlobalSearch::ProtocolSerializer,
                 meta: {
                   total: @search_count,
                   next_page: @records.try(:next_page)
                 }
          return
        when 'label_templates'
          return render json: [], meta: { disabled: true }, status: :ok unless LabelTemplate.enabled?

          @label_template_search_count = fetch_cached_count(LabelTemplate)
          search_label_templates
          paginate_records

          render json: @records,
                 each_serializer: GlobalSearch::LabelTemplateSerializer,
                 meta: {
                   total: @search_count,
                   next_page: @records.try(:next_page)
                 }
          return
        when 'repository_rows'
          @repository_row_search_count = fetch_cached_count(RepositoryRow)
          search_repository_rows
          paginate_records

          render json: @records,
                 each_serializer: GlobalSearch::RepositoryRowSerializer,
                 meta: {
                   total: @search_count,
                   next_page: @records.try(:next_page)
                 }
          return
        when 'assets'
          @asset_search_count = fetch_cached_count(Asset)
          search_assets
          includes = [{ step: { protocol: { my_module: :experiment } } }, { result: { my_module: :experiment } }, :team]
          paginate_records

          render json: @records.includes(includes),
                 each_serializer: GlobalSearch::AssetSerializer,
                 meta: {
                   total: @search_count,
                   next_page: @records.try(:next_page)
                 }
          return
        end
      end
    end
  end

  def new
  end

  def quick
    results = if params[:filter].present?
                object_quick_search(params[:filter].singularize)
              else
                Constants::QUICK_SEARCH_SEARCHABLE_OBJECTS.filter_map do |object|
                  next if object == 'label_template' && !LabelTemplate.enabled?

                  object_quick_search(object)
                end.flatten.sort_by(&:updated_at).reverse.take(Constants::QUICK_SEARCH_LIMIT)
              end

    render json: results, each_serializer: QuickSearchSerializer
  end

  private

  def object_quick_search(class_name)
    search_model = class_name.to_s.camelize.constantize
    search_method = search_model.method(search_model.respond_to?(:code) ? :search_by_name_and_id : :search_by_name)

    search_method.call(current_user,
                       current_team,
                       params[:query],
                       limit: Constants::QUICK_SEARCH_LIMIT)
                 .order(updated_at: :desc)
  end

  def load_vars
    query = (params.fetch(:q) { '' }).strip
    @filters = params[:filters]
    @include_archived = @filters.blank? || @filters[:include_archived] == 'true'
    @teams = (@filters.present? && @filters[:teams]&.values) || current_user.teams
    @display_query = query

    splited_query = query.split
    @search_query = ''
    splited_query.each_with_index do |w, i|
      if w.length >= Constants::NAME_MIN_LENGTH &&
         w.length <= Constants::TEXT_MAX_LENGTH
        @search_query += "#{splited_query[i]} "
      end
    end
    if @search_query.blank?
      flash[:error] = t('general.query.wrong_query',
                        min_length: Constants::NAME_MIN_LENGTH,
                        max_length: Constants::TEXT_MAX_LENGTH)
      redirect_back(fallback_location: root_path)
    else
      @search_query.strip!
    end
  end

  protected

  def generate_search_id
    SecureRandom.urlsafe_base64(32)
  end

  def search_by_name(model, options={})
    @records = model.search(current_user,
                            @include_archived,
                            @search_query,
                            nil,
                            teams: @teams,
                            users: @users,
                            options: options)

    filter_records(model) if @filters.present?
    sort_records
  end

  def count_by_name(model, options = {})
    model.search(current_user,
                 @include_archived,
                 @search_query,
                 nil,
                 teams: @teams,
                 users: @users,
                 options: options).size
  end

  def fetch_cached_count(type)
    exp = 5.minutes
    Rails.cache.fetch(
      "#{@search_id}/#{type.name.underscore}_search_count", expires_in: exp
    ) do
      count_by_name(type)
    end
  end

  def search_projects
    @records = Project.none
    search_by_name(Project) if @project_search_count.positive?
    @search_count = @project_search_count
  end

  def search_project_folders
    @records = ProjectFolder.none
    @records = search_by_name(ProjectFolder) if @project_folder_search_count.positive?
    @search_count = @project_folder_search_count
  end

  def search_experiments
    @records = Experiment.none
    @records = search_by_name(Experiment) if @experiment_search_count.positive?
    @search_count = @experiment_search_count
  end

  def search_modules
    @records = MyModule.none
    @records = search_by_name(MyModule) if @module_search_count.positive?
    @search_count = @module_search_count
  end

  def search_module_protocols
    @records = search_by_name(Protocol, { in_repository: false })
    @search_count = @records.count
  end

  def search_results
    @records = Result.none
    @records = search_by_name(Result) if @result_search_count.positive?
    @search_count = @result_search_count
  end

  def search_reports
    @records = Report.none
    @records = search_by_name(Report) if @report_search_count.positive?
    @search_count = @report_search_count
  end

  def search_protocols
    @records = search_by_name(Protocol, { in_repository: true })
    @search_count = @records.count
  end

  def search_label_templates
    @records = LabelTemplate.none
    @records = search_by_name(LabelTemplate) if @label_template_search_count.positive?
    @search_count = @label_template_search_count
  end

  def search_steps
    @records = []
    @records = search_by_name(Step) if @step_search_count.positive?
    @search_count = @step_search_count
  end

  def search_repository_rows
    @records = RepositoryRow.none
    @records = search_by_name(RepositoryRow) if @repository_row_search_count.positive?
    @search_count = @repository_row_search_count
  end

  def search_assets
    @records = Asset.none
    @records = search_by_name(Asset) if @asset_search_count.positive?
    @search_count = @asset_search_count
  end

  def filter_records(model)
    filter_datetime!(model, :created_at) if @filters[:created_at].present?
    filter_datetime!(model, :updated_at) if @filters[:updated_at].present?
    filter_users!(model) if @filters[:users].present?
  end

  def sort_records
    @records = case params[:sort]
               when 'atoz'
                 @records.order(name: :asc)
               when 'ztoa'
                 @records.order(name: :desc)
               when 'created_asc'
                 @records.order(created_at: :asc)
               else
                 @records.order(created_at: :desc)
               end
  end

  def paginate_records
    @records = if params[:preview] == 'true'
                 @records.limit(Constants::GLOBAL_SEARCH_PREVIEW_LIMIT)
               else
                 @records.page(params[:page]).per(Constants::SEARCH_LIMIT)
               end
  end

  def filter_datetime!(model, attribute)
    model_name = model.model_name.collection
    if @filters[attribute][:on].present?
      from_date = Time.zone.parse(@filters[attribute][:on]).beginning_of_day.utc
      to_date = Time.zone.parse(@filters[attribute][:on]).end_of_day.utc
    elsif @filters[attribute][:from].present? && @filters[attribute][:to].present?
      from_date = Time.zone.parse(@filters[attribute][:from])
      to_date = Time.zone.parse(@filters[attribute][:to])
    end

    @records = @records.where("#{model_name}.#{attribute} >= ?", from_date) if from_date.present?
    @records = @records.where("#{model_name}.#{attribute} <= ?", to_date) if to_date.present?
  end

  def filter_users!(model)
    @records = @records.joins("INNER JOIN activities ON #{model.model_name.collection}.id = activities.subject_id
                               AND activities.subject_type= '#{model.name}'")
                       .where('activities.owner_id': @filters[:users]&.values)
  end
end
