class SearchController < ApplicationController
  before_action :load_vars, only: :index

  def index
    redirect_to new_search_path unless @search_query

    count_search_results

    search_projects if @search_category == :projects
    search_experiments if @search_category == :experiments
    search_modules if @search_category == :modules
    search_results if @search_category == :results
    search_tags if @search_category == :tags
    search_reports if @search_category == :reports
    search_protocols if @search_category == :protocols
    search_steps if @search_category == :steps
    search_checklists if @search_category == :checklists
    search_samples if @search_category == :samples
    if @search_category == :repositories && params[:repository]
      search_repository
    end
    search_assets if @search_category == :assets
    search_tables if @search_category == :tables
    search_comments if @search_category == :comments

    @search_pages = (@search_count.to_f / Constants::SEARCH_LIMIT.to_f).ceil
    @start_page = @search_page - 2
    @start_page = 1 if @start_page < 1
    @end_page = @start_page + 4

    if @end_page > @search_pages
      @end_page = @search_pages
      @start_page = @end_page - 4
      @start_page = 1 if @start_page < 1
    end
  end

  def new
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
      if @search_query.empty?
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

  def search_by_name(model)
    model.search(current_user,
                 true,
                 @search_query,
                 @search_page,
                 nil,
                 match_case: @search_case,
                 whole_word: @search_whole_word,
                 whole_phrase: @search_whole_phrase)
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
    count_total = 0
    search_results = Repository.search(current_user,
                                       true,
                                       @search_query,
                                       Constants::SEARCH_NO_LIMIT,
                                       nil,
                                       match_case: @search_case,
                                       whole_word: @search_whole_word,
                                       whole_phrase: @search_whole_phrase)
    @repository_search_count = {}
    current_user.teams.includes(:repositories).each do |team|
      team_results = {}
      team_results[:count] = 0
      team_results[:repositories] = {}
      team.repositories.each do |repository|
        repository_results = {}
        repository_results[:id] = repository.id
        repository_results[:count] = 0
        search_results.each do |result|
          if repository.id == result.id
            count_total += result.counter
            repository_results[:count] += result.counter
          end
        end
        team_results[:repositories][repository.name] = repository_results
        team_results[:count] += repository_results[:count]
      end
      @repository_search_count[team.name] = team_results
    end
    count_total
  end

  def count_search_results
    @project_search_count = count_by_name Project
    @experiment_search_count = count_by_name Experiment
    @module_search_count = count_by_name MyModule
    @result_search_count = count_by_name Result
    @tag_search_count = count_by_name Tag
    @report_search_count = count_by_name Report
    @protocol_search_count = count_by_name Protocol
    @step_search_count = count_by_name Step
    @checklist_search_count = count_by_name Checklist
    @sample_search_count = count_by_name Sample
    @repository_search_count_total = count_by_repository
    @asset_search_count = count_by_name Asset
    @table_search_count = count_by_name Table
    @comment_search_count = count_by_name Comment

    @search_results_count = @project_search_count
    @search_results_count += @experiment_search_count
    @search_results_count += @module_search_count
    @search_results_count += @result_search_count
    @search_results_count += @tag_search_count
    @search_results_count += @report_search_count
    @search_results_count += @protocol_search_count
    @search_results_count += @step_search_count
    @search_results_count += @checklist_search_count
    @search_results_count += @sample_search_count
    @search_results_count += @repository_search_count_total
    @search_results_count += @asset_search_count
    @search_results_count += @table_search_count
    @search_results_count += @comment_search_count
  end

  def search_projects
    @project_results = []
    @project_results = search_by_name(Project) if @project_search_count > 0
    @search_count = @project_search_count
  end

  def search_experiments
    @experiment_results = []
    if @experiment_search_count > 0
      @experiment_results = search_by_name(Experiment)
    end
    @search_count = @experiment_search_count
  end

  def search_modules
    @module_results = []
    @module_results = search_by_name(MyModule) if @module_search_count > 0
    @search_count = @module_search_count
  end

  def search_results
    @result_results = []
    @result_results = search_by_name(Result) if @result_search_count > 0
    @search_count = @result_search_count
  end

  def search_tags
    @tag_results = []
    @tag_results = search_by_name(Tag) if @tag_search_count > 0
    @search_count = @tag_search_count
  end

  def search_reports
    @report_results = []
    @report_results = search_by_name(Report) if @report_search_count > 0
    @search_count = @report_search_count
  end

  def search_protocols
    @protocol_results = []
    @protocol_results = search_by_name(Protocol) if @protocol_search_count > 0
    @search_count = @protocol_search_count
  end

  def search_steps
    @step_results = []
    @step_results = search_by_name(Step) if @step_search_count > 0
    @search_count = @step_search_count
  end

  def search_checklists
    @checklist_results = []
    if @checklist_search_count > 0
      @checklist_results = search_by_name(Checklist)
    end
    @search_count = @checklist_search_count
  end

  def search_samples
    @sample_results = []
    @sample_results = search_by_name(Sample) if @sample_search_count > 0
    @search_count = @sample_search_count
  end

  def search_repository
    @repository = Repository.find_by_id(params[:repository])
    render_403 unless can_view_repository(@repository)
    @repository_results = []
    if @repository_search_count_total > 0
      @repository_results =
        RepositoryRow.search(@repository, @search_query, @search_page,
                             match_case: @search_case,
                             whole_word: @search_whole_word,
                             whole_phrase: @search_whole_phrase)
    end
    @search_count = @repository_search_count_total
  end

  def search_assets
    @asset_results = []
    @asset_results = search_by_name(Asset) if @asset_search_count > 0
    @search_count = @asset_search_count
  end

  def search_tables
    @table_results = []
    @table_results = search_by_name(Table) if @table_search_count > 0
    @search_count = @table_search_count
  end

  def search_comments
    @comment_results = []
    @comment_results = search_by_name(Comment) if @comment_search_count > 0
    @search_count = @comment_search_count
  end
end
