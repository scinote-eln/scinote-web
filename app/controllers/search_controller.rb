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
          if params[:preview] == 'true'
            results = @project_results&.limit(4) || []
          else
            results = @project_results.page(params[:page]).per(Constants::SEARCH_LIMIT)
          end

          render json: results.includes(:team, :project_folder),
                 each_serializer: GlobalSearch::ProjectSerializer,
                 meta: {
                  total: @search_count,
                  next_page: (results.next_page if results.respond_to?(:next_page)),
                }
        when 'project_folders'
          @project_folder_search_count = fetch_cached_count ProjectFolder
          search_project_folders
          results = if params[:preview] == 'true'
                      @project_folder_results.limit(Constants::GLOBAL_SEARCH_PREVIEW_LIMIT)
                    else
                      @project_folder_results.page(params[:page]).per(Constants::SEARCH_LIMIT)
                    end
          render json: results.includes(:team, :parent_folder),
                 each_serializer: GlobalSearch::ProjectFolderSerializer,
                 meta: {
                   total: @search_count,
                   next_page: results.try(:next_page)
                 }
          return
        when 'experiments'
          @experiment_search_count = fetch_cached_count Experiment
          search_experiments
          results = if params[:preview] == 'true'
                      @experiment_results.limit(Constants::GLOBAL_SEARCH_PREVIEW_LIMIT)
                    else
                      @experiment_results.page(params[:page]).per(Constants::SEARCH_LIMIT)
                    end
          render json: results.includes(project: :team),
                 each_serializer: GlobalSearch::ExperimentSerializer,
                 meta: {
                   total: @search_count,
                   next_page: results.try(:next_page)
                 }
          return
        when 'protocols'
          @protocol_search_count = fetch_cached_count(Protocol)
          search_protocols
          results = if params[:preview] == 'true'
                      @protocol_results&.limit(4) || []
                    else
                      @protocol_results.page(params[:page]).per(Constants::SEARCH_LIMIT)
                    end

          render json: results,
                 each_serializer: GlobalSearch::ProtocolSerializer,
                 meta: {
                          total: @search_count,
                          next_page: (results.next_page if results.respond_to?(:next_page)),
                        }
          return
        end

        #@search_id = params[:search_id] ? params[:search_id] : generate_search_id
        #
        #count_search_results
        #
        #search_projects if @search_category == :projects
        #search_project_folders if @search_category == :project_folders
        #search_experiments if @search_category == :experiments
        #search_modules if @search_category == :modules
        #search_results if @search_category == :results
        #search_tags if @search_category == :tags
        #search_reports if @search_category == :reports
        #search_protocols if @search_category == :protocols
        #search_steps if @search_category == :steps
        #search_checklists if @search_category == :checklists
        #if @search_category == :repositories && params[:repository]
        #  search_repository
        #end
        #search_assets if @search_category == :assets
        #search_tables if @search_category == :tables
        #search_comments if @search_category == :comments

        #@search_pages = (@search_count.to_f / Constants::SEARCH_LIMIT.to_f).ceil
        #@start_page = @search_page - 2
        #@start_page = 1 if @start_page < 1
        #@end_page = @start_page + 4

        #if @end_page > @search_pages
        #  @end_page = @search_pages
        #  @start_page = @end_page - 4
        #  @start_page = 1 if @start_page < 1
        #end
      end
    end
  end

  def new
  end

  def quick
    results = [
      Project.first,
      Experiment.first,
      MyModule.first,
      Protocol.first,
      RepositoryRow.first,
      Result.first,
      Step.first,
      Report.first,
      LabelTemplate.first
    ].compact

    render json: results, each_serializer: QuickSearchSerializer
  end

  private

  def load_vars
    query = (params.fetch(:q) { '' }).strip
    @search_category = params[:category] || ''
    @search_category = @search_category.to_sym
    @search_page = params[:page].to_i || 1
    @search_case = params[:match_case] == 'true'
    @search_whole_word = params[:whole_word] == 'true'
    @search_whole_phrase = params[:whole_phrase] == 'true'
    @display_query = query

    if @search_whole_phrase || query.count(' ').zero?
      if query.length < Constants::NAME_MIN_LENGTH
        flash[:error] = t('general.query.length_too_short',
                          min_length: Constants::NAME_MIN_LENGTH)
        redirect_back(fallback_location: root_path)
      elsif query.length > Constants::TEXT_MAX_LENGTH
        flash[:error] = t('general.query.length_too_long',
                          max_length: Constants::TEXT_MAX_LENGTH)
        redirect_back(fallback_location: root_path)
      else
        @search_query = query
      end
    else
      # splits the search query to validate all entries
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
    @search_page = 1 if @search_page < 1
  end

  protected

  def generate_search_id
    SecureRandom.urlsafe_base64(32)
  end

  def search_by_name(model)
    model.search(current_user,
                 true,
                 @search_query,
                 @search_page,
                 nil,
                 match_case: @search_case,
                 whole_word: @search_whole_word,
                 whole_phrase: @search_whole_phrase)
         .order(created_at: :desc)
  end

  def count_by_name(model)
    model.search(current_user,
                 true,
                 @search_query,
                 Constants::SEARCH_NO_LIMIT,
                 nil,
                 match_case: @search_case,
                 whole_word: @search_whole_word,
                 whole_phrase: @search_whole_phrase).size
  end

  def count_by_repository
    @repository_search_count =
      Rails.cache.fetch("#{@search_id}/repository_search_count",
                        expires_in: 5.minutes) do
        search_count = {}
        search_results = Repository.search(current_user,
                                           @search_query,
                                           Constants::SEARCH_NO_LIMIT,
                                           nil,
                                           match_case: @search_case,
                                           whole_word: @search_whole_word,
                                           whole_phrase: @search_whole_phrase)

        current_user.teams.includes(:repositories).each do |team|
          team_results = {}
          team_results[:team] = team
          team_results[:count] = 0
          team_results[:repositories] = {}
          Repository.accessible_by_teams(team).each do |repository|
            repository_results = {}
            repository_results[:id] = repository.id
            repository_results[:repository] = repository
            repository_results[:count] = 0
            search_results.each do |result|
              repository_results[:count] += result.counter if repository.id == result.id
            end
            team_results[:repositories][repository.name] = repository_results
            team_results[:count] += repository_results[:count]
          end
          search_count[team.name] = team_results
        end
        search_count
      end

    count_total = 0
    @repository_search_count.each_value do |team_results|
      count_total += team_results[:count]
    end
    count_total
  end

  def current_repository_search_count
    @repository_search_count.each_value do |counter|
      res = counter[:repositories].values.detect do |rep|
        rep[:id] == @repository.id
      end
      return res[:count] if res && res[:count]
    end
  end

  def count_search_results
    @project_search_count = fetch_cached_count Project
    @project_folder_search_count = fetch_cached_count ProjectFolder
    @experiment_search_count = fetch_cached_count Experiment
    @module_search_count = fetch_cached_count MyModule
    @result_search_count = fetch_cached_count Result
    @tag_search_count = fetch_cached_count Tag
    @report_search_count = fetch_cached_count Report
    @protocol_search_count = fetch_cached_count Protocol
    @step_search_count = fetch_cached_count Step
    @checklist_search_count = fetch_cached_count Checklist
    @repository_search_count_total = count_by_repository
    @asset_search_count = fetch_cached_count Asset
    @table_search_count = fetch_cached_count Table
    @comment_search_count = fetch_cached_count Comment

    @search_results_count = @project_search_count
    @search_results_count += @project_folder_search_count
    @search_results_count += @experiment_search_count
    @search_results_count += @module_search_count
    @search_results_count += @result_search_count
    @search_results_count += @tag_search_count
    @search_results_count += @report_search_count
    @search_results_count += @protocol_search_count
    @search_results_count += @step_search_count
    @search_results_count += @checklist_search_count
    @search_results_count += @repository_search_count_total
    @search_results_count += @asset_search_count
    @search_results_count += @table_search_count
    @search_results_count += @comment_search_count
  end

  def fetch_cached_count(type)
    exp = 5.minutes
    Rails.cache.fetch(
      "#{@search_id}/#{type.name.underscore}_search_count", expires_in: exp
    ) do
      count_by_name type
    end
  end

  def search_projects
    @project_results = Project.none
    @project_results = search_by_name(Project) if @project_search_count.positive?
    @search_count = @project_search_count
  end

  def search_project_folders
    @project_folder_results = ProjectFolder.none
    @project_folder_results = search_by_name(ProjectFolder) if @project_folder_search_count.positive?
    @search_count = @project_folder_search_count
  end

  def search_experiments
    @experiment_results = Experiment.none
    @experiment_results = search_by_name(Experiment) if @experiment_search_count.positive?
    @search_count = @experiment_search_count
  end

  def search_modules
    @module_results = []
    @module_results = search_by_name(MyModule) if @module_search_count.positive?
    @search_count = @module_search_count
  end

  def search_results
    @result_results = []
    @result_results = search_by_name(Result) if @result_search_count.positive?
    @search_count = @result_search_count
  end

  def search_tags
    @tag_results = []
    @tag_results = search_by_name(Tag) if @tag_search_count.positive?
    @search_count = @tag_search_count
  end

  def search_reports
    @report_results = []
    @report_results = search_by_name(Report) if @report_search_count.positive?
    @search_count = @report_search_count
  end

  def search_protocols
    @protocol_results = []
    @protocol_results = search_by_name(Protocol) if @protocol_search_count.positive?
    @search_count = @protocol_search_count
  end

  def search_steps
    @step_results = []
    @step_results = search_by_name(Step) if @step_search_count.positive?
    @search_count = @step_search_count
  end

  def search_checklists
    @checklist_results = []
    @checklist_results = search_by_name(Checklist) if @checklist_search_count.positive?
    @search_count = @checklist_search_count
  end

  def search_repository
    @repository = Repository.find_by(id: params[:repository])
    unless current_user.teams.include?(@repository.team) || @repository.private_shared_with?(current_user.teams)
      render_403
    end
    @repository_results = []
    if @repository_search_count_total.positive?
      @repository_results =
        Repository.search(current_user, @search_query, @search_page,
                          @repository,
                          match_case: @search_case,
                          whole_word: @search_whole_word,
                          whole_phrase: @search_whole_phrase)
    end
    @search_count = current_repository_search_count
  end

  def search_assets
    @asset_results = []
    @asset_results = search_by_name(Asset) if @asset_search_count.positive?
    @search_count = @asset_search_count
  end

  def search_tables
    @table_results = []
    @table_results = search_by_name(Table) if @table_search_count.positive?
    @search_count = @table_search_count
  end

  def search_comments
    @comment_results = []
    @comment_results = search_by_name(Comment) if @comment_search_count.positive?
    @search_count = @comment_search_count
  end
end
