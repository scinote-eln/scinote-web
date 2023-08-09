# frozen_string_literal: true

class GeneSequenceAssetsController < ApplicationController
  include ActiveStorage::SetCurrent

  skip_before_action :verify_authenticity_token

  before_action :check_open_vector_service_enabled, except: :edit
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
    @ove_enabled = OpenVectorEditorService.enabled?
    render :edit, layout: false
  end

  def create
    save_asset!
    head :ok
  end

  def update
    save_asset!
    head :ok
  end

  private

  def save_asset!
    ActiveRecord::Base.transaction do
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

      @asset.save!
    end
  end

  def ensure_asset!
    return if @asset
    return unless @parent

    @asset = @parent.assets.create!(last_modified_by: current_user, team: current_team)
  end

  def load_vars
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
      return render_403 unless can_read_my_module?(@my_module)
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
      can_manage_my_module?(@parent)
    else
      false
    end
  end
end
