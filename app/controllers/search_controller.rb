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
          search_by_name(Project)

          render json: @records.includes(:team, :project_folder),
                 each_serializer: GlobalSearch::ProjectSerializer,
                 meta: {
                   total: @records.total_count,
                   next_page: (@records.next_page if @records.respond_to?(:next_page)),
                 }
        when 'project_folders'
          search_by_name(ProjectFolder)

          render json: @records.includes(:team, :parent_folder),
                 each_serializer: GlobalSearch::ProjectFolderSerializer,
                 meta: {
                   total: @records.total_count,
                   next_page: @records.next_page
                 }
          return
        when 'reports'
          search_by_name(Report)

          render json: @records.includes(:team, :project, :user),
                 each_serializer: GlobalSearch::ReportSerializer,
                 meta: {
                   total: @records.total_count,
                   next_page: @records.next_page
                 }
          return
        when 'module_protocols'
          search_by_name(Protocol, { in_repository: false })

          render json: @records.joins({ my_module: :experiment }, :team),
                 each_serializer: GlobalSearch::MyModuleProtocolSerializer,
                 meta: {
                   total: @records.total_count,
                   next_page: @records.next_page
                 }
          return
        when 'experiments'
          search_by_name(Experiment)

          render json: @records.includes(project: :team),
                 each_serializer: GlobalSearch::ExperimentSerializer,
                 meta: {
                   total: @records.total_count,
                   next_page: @records.next_page
                 }
          return
        when 'tasks'
          search_by_name(MyModule)

          render json: @records.includes(experiment: { project: :team }),
                 each_serializer: GlobalSearch::MyModuleSerializer,
                 meta: {
                   total: @records.total_count,
                   next_page: @records.next_page
                 }
          return
        when 'results'
          search_by_name(Result)

          render json: @records.includes(my_module: { experiment: { project: :team } }),
                 each_serializer: GlobalSearch::ResultSerializer,
                 meta: {
                   total: @records.total_count,
                   next_page: @records.next_page
                 }
          return
        when 'protocols'
          search_by_name(Protocol, { in_repository: true })

          render json: @records,
                 each_serializer: GlobalSearch::ProtocolSerializer,
                 meta: {
                   total: @records.total_count,
                   next_page: @records.next_page
                 }
          return
        when 'label_templates'
          return render json: [], meta: { disabled: true }, status: :ok unless LabelTemplate.enabled?

          search_by_name(LabelTemplate)

          render json: @records,
                 each_serializer: GlobalSearch::LabelTemplateSerializer,
                 meta: {
                   total: @records.total_count,
                   next_page: @records.next_page
                 }
          return
        when 'repository_rows'
          search_by_name(RepositoryRow)

          render json: @records,
                 each_serializer: GlobalSearch::RepositoryRowSerializer,
                 meta: {
                   total: @records.total_count,
                   next_page: @records.next_page
                 }
          return
        when 'assets'
          search_by_name(Asset)
          includes = [{ step: { protocol: { my_module: :experiment } } }, { result: { my_module: :experiment } }, :team]

          render json: @records.includes(includes),
                 each_serializer: GlobalSearch::AssetSerializer,
                 meta: {
                   total: @records.total_count,
                   next_page: @records.next_page
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

  def search_by_name(model, options = {})
    @records = model.search(current_user,
                            @include_archived,
                            @search_query,
                            nil,
                            teams: @teams,
                            users: @users,
                            options: options)

    filter_records(model) if @filters.present?
    sort_records
    paginate_records
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
                 @records.page(params[:page]).per(Constants::GLOBAL_SEARCH_PREVIEW_LIMIT)
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
