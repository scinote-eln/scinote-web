# frozen_string_literal: true

class ProjectJsonExportService
  require 'net/http'

  def initialize(project_id, experiment_ids, task_ids, callback)
    @project = Project.find_by(id: project_id)
    @experiment_ids = experiment_ids
    @task_ids = task_ids
    @callback = callback
    @storage_location = ENV['ACTIVESTORAGE_SERVICE'] ? ENV['ACTIVESTORAGE_SERVICE'] : 'local'
    @bucket_location = ENV['ACTIVESTORAGE_SERVICE'] && ENV['S3_BUCKET'] ? 
                          ENV['S3_BUCKET'] : ActiveStorage::Blob.service.current_host
    @request_json = {}
  end

  def generate_data
    exps = Experiment.includes(:project)
                     .where(id: @experiment_ids)

    project = @project.as_json(only: %i(id name))
    experiments = []
    exps.find_each do |exp|
      experiment = exp.as_json(only: %i(id name description))
      tasks = []
      exp.my_modules.where(archived: false).find_each do |tsk|
        if @task_ids.map(&:to_i).include?(tsk.id.to_i)
          task = tsk.as_json(only: %i(id name description))
          t_m_files = tsk.tiny_mce_assets.map { |asset| tiny_mce_file_json(asset) }
          task['tiny_mce_files'] = t_m_files if t_m_files.any?
          steps = []
          task['protocols'] = []
          tsk.protocols.find_each do |prtcl|
            task['protocols'] << protocol_json(prtcl)
            prtcl.steps.order(:position).find_each { |stp| steps << step_json(stp) }
          end
          task['steps'] = steps if steps.any?
          results = []
          tsk.results
             .where(archived: false)
             .order(created_at: :desc)
             .find_each { |res| results << result_json(res) }
          task['results'] = results if results.any?
          tasks << task
        end
      end
      experiment['tasks'] = tasks if tasks.any?
      experiments << experiment
    end
    project['experiments'] = experiments if experiments.any?
    @request_json['project'] = project
  end

  def post_request
    url = URI.parse(@callback)
    req = Net::HTTP::Post.new(url.request_uri)
    req.body = @request_json.to_s
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
    if ( ENV['ACTIVESTORAGE_SERVICE'] && ENV['S3_BUCKET'] )
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
    if ( ENV['ACTIVESTORAGE_SERVICE'] && ENV['S3_BUCKET'] )
      { 'storage' => @storage_location,
        'id' => asset.id,
        'bucket' => ENV['S3_BUCKET'],
        'key' => ActiveStorage::Blob.service.path_for(asset.image.key)
      }
    else
      { 'storage' => @storage_location,
        'id' => asset.id,
        'url' => Rails.application.routes.url_helpers.url_for(asset.image)
      }
    end
  end

  def asset_url(asset)
    ENV['MAIL_SERVER_URL'] + Rails.application.routes.url_helpers.asset_file_url_path(asset)
  end
end
