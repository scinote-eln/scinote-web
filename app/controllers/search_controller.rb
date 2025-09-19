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
          @model = Project
          search_by_name
          @records = @records.preload(:team, :project_folder)
        when 'project_folders'
          @model = ProjectFolder
          search_by_name
          @records = @records.preload(:team, :parent_folder)
        when 'reports'
          @model = Report
          search_by_name
          @records = @records.preload(:team, :project, :user)
        when 'module_protocols'
          @model = Protocol
          @serializer = GlobalSearch::MyModuleProtocolSerializer
          search_by_name({ in_repository: false })
          @records = @records.preload({ my_module: :experiment }, :team)
        when 'experiments'
          @model = Experiment
          search_by_name
          @records = @records.preload(project: :team)
        when 'tasks'
          @model = MyModule
          search_by_name
          @records = @records.preload(experiment: { project: :team })
        when 'results'
          @model = Result
          search_by_name
          @records = @records.preload(my_module: { experiment: { project: :team } })
        when 'protocols'
          @model = Protocol
          search_by_name({ in_repository: true })
          @records = @records.preload(:team, :added_by)
        when 'label_templates'
          return render json: [], meta: { disabled: true, total: 0 } unless LabelTemplate.enabled?

          @model = LabelTemplate
          search_by_name
        when 'repository_rows'
          @model = RepositoryRow
          search_by_name
          @records = @records.preload(:created_by, repository: :team)
        when 'assets'
          @model = Asset
          search_by_name
          @records = @records.preload([:team, { step: { protocol: { my_module: :experiment } } }, { result: { my_module: :experiment } }])
        else
          return render_404
        end

        @serializer ||= "GlobalSearch::#{@model.name}Serializer".constantize

        render json: @records,
               each_serializer: @serializer,
               adapter: :json,
               root: 'data',
               meta: {
                 total: @records.present? ? @records.take.filtered_count : 0,
                 next_page: @records.next_page
               }
      end
    end
  end

  def new
  end

  def quick
    results = if params[:filter].present?
                class_name = params[:filter].singularize
                return render_422(t('general.invalid_params')) unless Constants::QUICK_SEARCH_SEARCHABLE_OBJECTS.include?(class_name)

                object_quick_search(class_name)
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
    search_object_classes = ["#{class_name.pluralize}.name"]
    search_object_classes << search_model::PREFIXED_ID_SQL if search_model.respond_to?(:code)

    search_model.search_by_search_fields_with_boolean(current_user,
                                                      current_team,
                                                      params[:query],
                                                      search_object_classes,
                                                      limit: Constants::QUICK_SEARCH_LIMIT)
                .order(updated_at: :desc)
  end

  def load_vars
    query = (params.fetch(:q) { '' }).strip
    @filters = params[:filters]
    @include_archived = @filters.blank? || @filters[:include_archived] == 'true'
    @teams = @filters.present? && @filters[:teams]&.values ? current_user.teams.where(id: @filters[:teams].values) : current_user.teams
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

  def search_by_name(options = {})
    @records = @model.search(current_user,
                             @include_archived,
                             @search_query,
                             @teams,
                             options)
                     .select("COUNT(\"#{@model.table_name}\".\"id\") OVER() AS filtered_count")
                     .select("\"#{@model.table_name}\".*")

    filter_records if @filters.present?
    sort_records
    paginate_records
  end

  def filter_records
    filter_datetime!(:created_at) if @filters[:created_at].present?
    filter_datetime!(:updated_at) if @filters[:updated_at].present?
    filter_users! if @filters[:users].present?
  end

  def sort_records
    @records = case params[:sort]
               when 'atoz'
                 sort_attribute = @model.name == 'Asset' ? 'active_storage_blobs.filename' : 'name'
                 @records.order(sort_attribute => :asc)
               when 'ztoa'
                 sort_attribute = @model.name == 'Asset' ? 'active_storage_blobs.filename' : 'name'
                 @records.order(sort_attribute => :desc)
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
    @records.without_count
  end

  def filter_datetime!(attribute)
    model_name = @model.model_name.collection
    if @filters[attribute][:on].present?
      from_date = Time.zone.parse(@filters[attribute][:on]).beginning_of_day.utc
      to_date = Time.zone.parse(@filters[attribute][:on]).end_of_day.utc
    end

    from_date = Time.zone.parse(@filters[attribute][:from]) if @filters[attribute][:from].present?
    to_date = Time.zone.parse(@filters[attribute][:to]) if @filters[attribute][:to].present?

    @records = @records.where("#{model_name}.#{attribute} >= ?", from_date) if from_date.present?
    @records = @records.where("#{model_name}.#{attribute} <= ?", to_date) if to_date.present?
  end

  def filter_users!
    @records = @records.joins("INNER JOIN activities ON #{@model.model_name.collection}.id = activities.subject_id
                               AND activities.subject_type= '#{@model.name}'")

    user_ids = @filters[:users]&.values
    @records = if @model.name == 'MyModule'
                 @records.where('activities.owner_id IN (?) OR users.id IN (?)', user_ids, user_ids)
               else
                 @records.where('activities.owner_id': user_ids)
               end
  end
end
