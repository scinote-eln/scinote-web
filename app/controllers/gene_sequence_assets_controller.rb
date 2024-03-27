# frozen_string_literal: true

class GeneSequenceAssetsController < ApplicationController
  include ActiveStorage::SetCurrent

  skip_before_action :verify_authenticity_token

  before_action :check_open_vector_service_enabled, except: %i(new edit)
  before_action :load_vars, except: %i(new create)
  before_action :load_create_vars, only: %i(new create)

  before_action :check_read_permission
  before_action :check_manage_permission, only: %i(new update create)

  def new
    render :edit, layout: false
  end

  def edit
    @file_url = rails_representation_url(@asset.file)
    @file_name = @asset.render_file_name
    log_activity('sequence_asset_edit_started')
    render :edit, layout: false
  end

  def create
    save_asset!

    case @parent
    when Step
      log_activity('sequence_asset_added')
    when Result
      log_result_activity(
        :sequence_on_result_added,
        @parent,
        file: @asset.file_name,
        user: current_user.id
      )
    end

    head :ok
  end

  def update
    save_asset!

    case @parent
    when Step
      log_activity('sequence_asset_edit_finished')
    when Result
      log_result_activity(
        :sequence_on_result_edited,
        @parent,
        file: @asset.file_name,
        user: current_user.id
      )
    end

    head :ok
  end

  def destroy
    log_activity('sequence_asset_deleted')
    head :ok
  end

  private

  def save_asset!
    ActiveRecord::Base.transaction do
      view_mode = @asset.view_mode if @asset

      ensure_asset!

      @asset.file.purge
      @asset.preview_image.purge

      @asset.file.attach(
        io: StringIO.new(params[:sequence_data].to_json),
        filename: "#{params[:sequence_name]}.json"
      )

      @asset.preview_image.attach(
        io: StringIO.new(Base64.decode64(params[:base64_image].split(',').last)),
        filename: "#{params[:sequence_name]}.png"
      )

      file = @asset.file

      file.blob.metadata['asset_type'] = 'gene_sequence'
      file.blob.metadata['name'] = params[:sequence_name]
      file.save!
      @asset.view_mode = view_mode || @parent.assets_view_mode
      @asset.last_modified_by = current_user
      @asset.save!
    end
  end

  def ensure_asset!
    return if @asset
    return unless @parent

    @asset = @parent.assets.create!(last_modified_by: current_user, team: current_team)
  end

  def load_vars
    @ove_enabled = OpenVectorEditorService.enabled?
    @asset = current_team.assets.find_by(id: params[:id])
    return render_404 unless @asset

    @parent ||= @asset.step
    @parent ||= @asset.result

    case @parent
    when Step
      @protocol = @parent.protocol
    when Result
      @my_module = @parent.my_module
    end
  end

  def load_create_vars
    @ove_enabled = OpenVectorEditorService.enabled?
    @parent = case params[:parent_type]
              when 'Step'
                Step.find_by(id: params[:parent_id])
              when 'Result'
                Result.find_by(id: params[:parent_id])
              end

    case @parent
    when Step
      @protocol = @parent.protocol
    when Result
      @result = @parent
    end
  end

  def check_read_permission
    case @parent
    when Step
      return render_403 unless can_read_protocol_in_module?(@protocol) ||
                               can_read_protocol_in_repository?(@protocol)
    when Result
      return render_403 unless can_read_result?(@parent)
    else
      render_403
    end
  end

  def check_manage_permission
    render_403 unless asset_managable?
  end

  def check_open_vector_service_enabled
    render_403 unless OpenVectorEditorService.enabled?
  end

  helper_method :asset_managable?
  def asset_managable?
    case @parent
    when Step
      can_manage_step?(@parent)
    when Result
      can_manage_result?(@parent)
    else
      false
    end
  end

  def log_activity(type_of, project = nil, message_items = {})
    return unless @parent.is_a?(Step)

    my_module = @parent.my_module
    default_items = {
      protocol: @parent.protocol.id,
      step: @parent.id,
      asset_name: { id: @asset.id, value_for: 'file_name' },
      step_position: { id: @parent.id, value_for: 'position_plus_one' }
    }

    if my_module
      project = my_module.project
      default_items[:my_module] = my_module.id
      type_of = "task_#{type_of}".to_sym
    else
      type_of = "protocol_#{type_of}".to_sym
    end

    message_items = default_items.merge(message_items)

    Activities::CreateActivityService.call(
      activity_type: type_of,
      owner: current_user,
      team: @parent.protocol.team,
      subject: @parent.protocol,
      message_items: message_items,
      project: project
    )
  end

  def log_result_activity(type_of, result, message_items)
    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            subject: result,
            team: result.my_module.team,
            project: result.my_module.project,
            message_items: {
              result: result.id
            }.merge(message_items))
  end
end
