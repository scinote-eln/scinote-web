# frozen_string_literal: true

class ProjectsJsonExportService
  include Canaid::Helpers::PermissionsHelper
  require 'net/http'

  def initialize(task_ids, callback, user)
    @user = user
    @task_ids = task_ids
    @experiment_ids = MyModule.where(id: @task_ids).pluck(:experiment_id).uniq
    @project_ids = Experiment.where(id: @experiment_ids).pluck(:project_id).uniq
    @callback = callback
    @storage_location = ENV['ACTIVESTORAGE_SERVICE'] || 'local'
    @request_json = {}
  end

  def generate_data
    project_json = []
    projects = Project.where(id: @project_ids)
    projects.find_each do |prj|
      next unless can_read_project?(@user, prj)

      project = prj.as_json(only: %i(id name))
      experiments = []
      prj.experiments.find_each do |exp|
        if @experiment_ids.map(&:to_i).include?(exp.id.to_i)
          next unless can_read_experiment?(@user, exp)

          experiment = exp.as_json(only: %i(id name description))
          tasks = []
          exp.my_modules.where(archived: false).find_each do |tsk|
            if @task_ids.map(&:to_i).include?(tsk.id.to_i)
              next unless can_read_my_module?(@user, tsk)

              tasks << task_json(tsk)
            end
          end
          experiment['tasks'] = tasks if tasks.any?
          experiments << experiment
        end
        project['experiments'] = experiments if experiments.any?
      end
      project_json << project
    end

    @request_json['projects'] = project_json
  end

  def post_request
    url = URI.parse(@callback)
    req = Net::HTTP::Post.new(url.request_uri, 'Content-Type': 'application/json;charset=utf-8')
    Rails.logger.info(@request_json.to_json)
    req.body = @request_json.to_json
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = (url.scheme == 'https')
    http.request(req)
  end

  private

  def protocol_json(protocol)
    protocol_json = protocol.as_json(only: %i(id description))
    t_m_files = protocol.tiny_mce_assets.map { |asset| tiny_mce_file_json(asset) }
    protocol_json['tiny_mce_files'] = t_m_files if t_m_files.any?
    protocol_json
  end

  def step_json(step)
    step_json = step.as_json(only: %i(id position name description completed))
    checklists = []
    step.checklists.find_each do |cl|
      checklist = cl.as_json(only: %i(id name))
      items = []
      cl.checklist_items.find_each do |cli|
        item = cli.as_json(only: %i(id position text checked))
        items << item
      end
      checklist['items'] = items if items.any?
      checklists << checklist
    end
    step_json['checklists'] = checklists if checklists.any?
    files = []
    step.assets.find_each do |asset|
      files << asset_file_json(asset)
    end
    step_json['files'] = files if files.any?
    t_m_files = []
    step.tiny_mce_assets.find_each do |asset|
      t_m_files << tiny_mce_file_json(asset)
    end
    step_json['tiny_mce_files'] = t_m_files if t_m_files.any?
    tables = []
    step.tables.find_each do |tbl|
      table = tbl.as_json(only: %i(id name))
      table['contents'] = JSON.parse(tbl.contents)['data']
      tables << table
    end
    step_json['tables'] = tables if tables.any?
    step_json
  end

  def task_json(task)
    task_json = task.as_json(only: %i(id name description))
    t_m_files = task.tiny_mce_assets.map { |asset| tiny_mce_file_json(asset) }
    task_json['tiny_mce_files'] = t_m_files if t_m_files.any?
    steps = []
    task_json['protocols'] = []
    task.protocols.find_each do |protocol|
      task_json['protocols'] << protocol_json(protocol)
      protocol.steps.order(:position).find_each { |stp| steps << step_json(stp) }
    end
    task_json['steps'] = steps if steps.any?
    results = []
    Rails.logger.info(task.results.to_yaml.to_s)
    task.results
        .where(archived: false)
        .order(created_at: :desc)
        .find_each { |res| results << result_json(res) }
    task_json['results'] = results if results.any?
    task_json
  end

  def result_json(result)
    result_json = result.as_json(only: %i(id name))
    if result.result_text
      result_json['type'] = 'text'
      result_json['text'] = result.result_text.text
      t_m_files = []
      result.result_text.tiny_mce_assets.find_each do |asset|
        t_m_files << tiny_mce_file_json(asset)
      end
      result_json['tiny_mce_files'] = t_m_files if t_m_files.any?
    elsif result.asset
      result_json['type'] = 'file'
      result_json['bucket'] = ENV['S3_BUCKET']
      result_json['key'] = ActiveStorage::Blob.service.path_for(result.asset.file.key)
      result_json['url'] = asset_url(result.asset)
    elsif result.table
      result_json['type'] = 'table'
      result_json['contents'] = JSON.parse(result.table.contents)['data']
    end
    result_json
  end

  def asset_file_json(asset)
    if ENV['ACTIVESTORAGE_SERVICE'] && ENV['S3_BUCKET']
      {
        'storage' => ENV['ACTIVESTORAGE_SERVICE'],
        'id' => asset.id,
        'bucket' => ENV['S3_BUCKET'],
        'key' => ActiveStorage::Blob.service.path_for(asset.file.key),
        'url' => asset_url(asset)
      }
    else
      {
        'storage' => 'local',
        'id' => asset.id,
        'url' => asset_url(asset)
      }
    end
  end

  def tiny_mce_file_json(asset)
    if ENV['ACTIVESTORAGE_SERVICE'] && ENV['S3_BUCKET']
      {
        'storage' => @storage_location,
        'id' => asset.id,
        'bucket' => ENV['S3_BUCKET'],
        'key' => ActiveStorage::Blob.service.path_for(asset.image.key)
      }
    else
      {
        'storage' => @storage_location,
        'id' => asset.id,
        'url' => Rails.application.routes.url_helpers.url_for(asset.image)
      }
    end
  end

  def asset_url(asset)
    ENV['MAIL_SERVER_URL'] + Rails.application.routes.url_helpers.asset_file_url_path(asset)
  end
end
