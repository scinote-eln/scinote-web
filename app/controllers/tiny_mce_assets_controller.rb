# frozen_string_literal: true

class TinyMceAssetsController < ApplicationController
  include MarvinJsActions
  include ActiveStorage::SetCurrent

  class UploadError < StandardError; end

  before_action :load_vars, only: %i(marvinjs_show marvinjs_update download)
  before_action :check_read_permissions, except: %i(create marvinjs_create marvinjs_update)
  before_action :check_edit_permissions, only: %i(marvinjs_update)

  def create
    status = :ok
    response_json = { images: [] }

    ActiveRecord::Base.transaction do
      images_params.each do |image|
        tiny_mce_asset =
          case image
          when ActionDispatch::Http::UploadedFile
            create_from_file(image)
          when ActionController::Parameters
            create_from_blob(ActiveStorage::Blob.find_signed(image[:blob_id]))
          end

        response_json[:images] << { url: rails_representation_url(tiny_mce_asset.image), token: Base62.encode(tiny_mce_asset.id) }
      end
    rescue ActiveRecord::RecordInvalid, UploadError => e
      response_json = { errors: e.message }
      status = :unprocessable_entity

      raise ActiveRecord::Rollback
    end

    render json: response_json, status: status
  end

  def download
    if @asset&.image&.attached?
      redirect_to rails_blob_path(@asset.image, disposition: 'attachment')
    else
      render_404
    end
  end

  def marvinjs_show
    create_edit_marvinjs_activity(@asset, current_user, :start_editing) if params[:show_action] == 'start_edit'

    render json: {
      name: @asset.image.metadata[:name],
      description: @asset.image.metadata[:description]
    }
  end

  def marvinjs_create
    tiny_mce_asset = MarvinJsService.create_tinymce_sketch(marvin_params, current_team)

    render json: {
      image: {
        url: rails_representation_url(tiny_mce_asset.preview),
        token: Base62.encode(tiny_mce_asset.id),
        source_type: tiny_mce_asset.image.metadata[:asset_type]
      }
    }, content_type: 'text/html'
  end

  def marvinjs_update
    tiny_mce_asset = MarvinJsService.update_tinymce_sketch(@asset, marvin_params)
    create_edit_marvinjs_activity(tiny_mce_asset, current_user, :finish_editing)

    render json: { url: rails_representation_url(tiny_mce_asset.preview), id: tiny_mce_asset.id }
  end

  private

  def create_from_file(file)
    unless file.content_type.match?(%r{^image/#{Regexp.union(Constants::WHITELISTED_IMAGE_TYPES)}})
      raise UploadError, I18n.t('tiny_mce.unsupported_image_format')
    end

    if file.size > Rails.configuration.x.file_max_size_mb.megabytes
      raise UploadError, I18n.t('general.file.size_exceeded', file_size: Rails.configuration.x.file_max_size_mb)
    end

    tiny_mce_asset = TinyMceAsset.create!(team_id: current_team.id, saved: false)
    tiny_mce_asset.image.attach(io: file, filename: file.original_filename)
    tiny_mce_asset
  end

  def create_from_blob(blob)
    tiny_mce_asset = TinyMceAsset.create!(team_id: current_team.id, saved: false)
    tiny_mce_asset.image.attach(blob)
    tiny_mce_asset
  end

  def load_vars
    @asset = current_team.tiny_mce_assets.find_by(id: Base62.decode(params[:id]))
    return render_404 unless @asset

    @assoc = @asset.object

    if @assoc.class == StepText
      @protocol = @assoc.step.protocol
    elsif @assoc.class == Protocol
      @protocol = @assoc
    elsif @assoc.class == MyModule
      @my_module = @assoc
    elsif @assoc.class == ResultText
      @my_module = @assoc.result.my_module
    end
  end

  def check_read_permissions
    if @assoc.class == StepText || @assoc.class == Protocol
      return render_403 unless can_read_protocol_in_module?(@protocol) ||
                               can_read_protocol_in_repository?(@protocol)
    elsif @assoc.class == ResultText || @assoc.class == MyModule
      return render_403 unless can_read_experiment?(@my_module.experiment)
    elsif @assoc.nil?
      return render_403 unless current_team == @asset.team
    else
      render_403
    end
  end

  def check_edit_permissions
    if @assoc.nil?
      if current_team == @asset.team
        return
      else
        return render_403
      end
    end
    case @assoc
    when StepText
      return render_403 unless can_manage_step_text?(@assoc)
    when Protocol
      return render_403 unless can_manage_protocol_in_module?(@protocol) ||
                               can_manage_protocol_draft_in_repository?(@protocol)
    when ResultText
      return render_403 unless can_manage_result_text?(@assoc)
    when MyModule
      return render_403 unless can_manage_my_module?(@my_module)
    else
      render_403
    end
  end

  def marvin_params
    params.permit(:id, :description, :object_id, :object_type, :name, :image)
  end

  def images_params
    params.require(:files)
  end
end
