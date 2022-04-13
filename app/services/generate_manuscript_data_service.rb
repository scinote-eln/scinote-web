# frozen_string_literal: true

class GenerateManuscriptDataService
  require 'net/http'

  def initialize(project_id, experiment_ids, task_ids, callback)
    @project_id = project_id
    @experiment_ids = experiment_ids
    @task_ids = task_ids
    @callback = callback
    @request_json = {}
  end

  def generate_data
    request_json = {}
    exps = Experiment.includes(:project)
                     .where(id: @experiment_ids)

    prj = Project.find_by(id: @project_id)
    project = prj.as_json(only: %i(id name))
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

  def protocol_json(prtcl)
    protocol = prtcl.as_json(only: %i(id description))
    t_m_files = prtcl.tiny_mce_assets.map { |asset| tiny_mce_file_json(asset) }
    protocol['tiny_mce_files'] = t_m_files if t_m_files.any?
    protocol
  end

  def step_json(stp)
    step = stp.as_json(only: %i(id position name description completed))
    checklists = []
    stp.checklists.find_each do |cl|
      checklist = cl.as_json(only: %i(id name))
      items = []
      cl.checklist_items.find_each do |cli|
        item = cli.as_json(only: %i(id position text checked))
        items << item
      end
      checklist['items'] = items if items.any?
      checklists << checklist
    end
    step['checklists'] = checklists if checklists.any?
    files = []
    stp.assets.find_each do |asset|
      files << {
        'id' => asset.id,
        'bucket' => ENV['S3_BUCKET'],
        'key' => ActiveStorage::Blob.service.path_for(asset.file.key),
        'url' => asset_url(asset)
      }
    end
    step['files'] = files if files.any?
    t_m_files = []
    stp.tiny_mce_assets.find_each do |asset|
      t_m_files << tiny_mce_file_json(asset)
    end
    step['tiny_mce_files'] = t_m_files if t_m_files.any?
    tables = []
    stp.tables.find_each do |tbl|
      table = tbl.as_json(only: %i(id name))
      table['contents'] = JSON.parse(tbl.contents)['data']
      tables << table
    end
    step['tables'] = tables if tables.any?
    step
  end

  def result_json(res)
    result = res.as_json(only: %i(id name))
    if res.result_text
      result['type'] = 'text'
      result['text'] = res.result_text.text
      t_m_files = []
      res.result_text.tiny_mce_assets.find_each do |asset|
        t_m_files << tiny_mce_file_json(asset)
      end
      result['tiny_mce_files'] = t_m_files if t_m_files.any?
    elsif res.asset
      result['type'] = 'file'
      result['bucket'] = ENV['S3_BUCKET']
      result['key'] = ActiveStorage::Blob.service.path_for(res.asset.file.key)
      result['url'] = asset_url(res.asset)
    elsif res.table
      result['type'] = 'table'
      result['contents'] = JSON.parse(res.table.contents)['data']
    end
    result
  end

  def tiny_mce_file_json(asset)
    { 'id' => asset.id,
      'bucket' => ENV['S3_BUCKET'],
      'key' => ActiveStorage::Blob.service.path_for(asset.image.key) }
  end

  def asset_url(asset)
    ENV['MAIL_SERVER_URL'] + Rails.application.routes.url_helpers.asset_file_url_path(asset)
  end
end
