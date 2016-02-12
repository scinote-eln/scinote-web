class SearchController < ApplicationController
  before_filter :load_vars, only: :index

  MIN_QUERY_CHARS = 3

  def index
    if not @search_query
      redirect_to new_search_path
    end

    count_search_results

    search_projects if @search_category == :projects
    search_modules if @search_category == :modules
    search_workflows if @search_category == :workflows
    search_tags if @search_category == :tags
    search_assets if @search_category == :assets
    search_steps if @search_category == :steps
    search_results if @search_category == :results
    search_samples if @search_category == :samples
    search_reports if @search_category == :reports
    search_comments if @search_category == :comments
    search_contents if @search_category == :contents

    @search_pages = (@search_count.to_f / SEARCH_LIMIT.to_f).ceil
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
    @search_query = params[:q] || ''
    @search_category = params[:category] || ''
    @search_category = @search_category.to_sym
    @search_page = params[:page].to_i || 1

    if @search_query.length < MIN_QUERY_CHARS
      flash[:error] = t'search.index.error.query_length', n: MIN_QUERY_CHARS
      redirect_to new_search_path
    end

    if @search_page < 1
      @search_page = 1
    end
  end

  protected

  def search_by_name(model)
    model.search(current_user, true, @search_query, @search_page)
  end

  def count_by_name(model)
    search_by_name(model).limit(nil).offset(nil).size
  end

  def count_search_results
    @project_search_count = count_by_name Project
    @module_search_count = count_by_name MyModule
    @workflow_search_count = count_by_name MyModuleGroup
    @tag_search_count = count_by_name Tag
    @asset_search_count = count_by_name Asset
    @step_search_count = count_by_name Step
    @result_search_count = count_by_name Result
    @sample_search_count = count_by_name Sample
    @report_search_count = count_by_name Report
    @comment_search_count = count_by_name Comment
    @contents_search_count = count_by_name AssetTextDatum

    @search_results_count = @project_search_count
    @search_results_count += @module_search_count
    @search_results_count += @workflow_search_count
    @search_results_count += @tag_search_count
    @search_results_count += @asset_search_count
    @search_results_count += @step_search_count
    @search_results_count += @result_search_count
    @search_results_count += @sample_search_count
    @search_results_count += @report_search_count
    @search_results_count += @comment_search_count
    @search_results_count += @contents_search_count
  end

  def search_projects
    @project_results = []
    if @project_search_count > 0 then
      @project_results = search_by_name Project
    end
    @search_count = @project_search_count
  end

  def search_modules
    @module_results = []
    if @module_search_count > 0 then
      @module_results = search_by_name MyModule
    end
    @search_count = @module_search_count
  end

  def search_workflows
    @workflow_results = []
    if @workflow_search_count > 0 then
      @workflow_results = search_by_name MyModuleGroup
    end
    @search_count = @workflow_search_count
  end

  def search_tags
    @tag_results = []
    if @tag_search_count > 0 then
      @tag_results = search_by_name Tag
    end
    @search_count = @tag_search_count
  end

  def search_assets
    @asset_results = []
    if @asset_search_count > 0 then
      @asset_results = search_by_name Asset
    end
    @search_count = @asset_search_count
  end

  def search_steps
    @step_results = []
    if @step_search_count > 0 then
      @step_results = search_by_name Step
    end
    @search_count = @step_search_count
  end

  def search_results
    @result_results = []
    if @result_search_count > 0 then
      @result_results = search_by_name Result
    end
    @search_count = @result_search_count
  end

  def search_samples
    @sample_results = []
    if @sample_search_count > 0 then
      @sample_results = search_by_name Sample
    end
    @search_count = @sample_search_count
  end

  def search_reports
    @report_results = []
    if @report_search_count > 0 then
      @report_results = search_by_name Report
    end
    @search_count = @report_search_count
  end

  def search_comments
    @comment_results = []
    if @comment_search_count > 0 then
      @comment_results = search_by_name Comment
    end
    @search_count = @comment_search_count
  end

  def search_contents
    @contents_results = []
    if @contents_search_count > 0 then
      @contents_results = search_by_name AssetTextDatum
    end
    @search_count = @contents_search_count
  end
end
