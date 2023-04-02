# frozen_string_literal: true

class TinyMceAssetsController < ApplicationController
  include MarvinJsActions
  include ActiveStorage::SetCurrent

  before_action :load_vars, only: %i(marvinjs_show marvinjs_update download)

  before_action :check_read_permission, only: %i(marvinjs_show marvinjs_update download)
  before_action :check_edit_permission, only: %i(marvinjs_update)

  def create
    status = :ok
    response_json = { images: [] }

    ActiveRecord::Base.transaction do
      images_params.each_with_index do |image, _i|
        unless image.content_type.match?(%r{^image/#{Regexp.union(Constants::WHITELISTED_IMAGE_TYPES)}})
          status = :unprocessable_entity
          response_json = { errors: I18n.t('tiny_mce.unsupported_image_format') }
        end

        if image.size > Rails.configuration.x.file_max_size_mb.megabytes
          status = :unprocessable_entity
          response_json = { errors: t('general.file.size_exceeded', file_size: Rails.configuration.x.file_max_size_mb) }
        end

        raise ActiveRecord::Rollback if response_json[:errors]

        tiny_img = TinyMceAsset.new(team_id: current_team.id, saved: false)

        tiny_img.save!
        tiny_img.image.attach(io: image, filename: image.original_filename)
        response_json[:images] << { url: url_for(tiny_img.image), token: Base62.encode(tiny_img.id) }
      end
    rescue ActiveRecord::RecordInvalid => e
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
    asset = current_team.tiny_mce_assets.find_by(id: Base62.decode(params[:id]))
    return render_404 unless asset

    create_edit_marvinjs_activity(asset, current_user, :start_editing) if params[:show_action] == 'start_edit'

    render json: {
      name: asset.image.metadata[:name],
      description: asset.image.metadata[:description]
    }
  end

  def marvinjs_create
    result = MarvinJsService.create_sketch(marvin_params, current_user, current_team)
    if result[:asset]
      render json: {
        image: {
          url: rails_representation_url(result[:asset].preview),
          token: Base62.encode(result[:asset].id),
          source_type: result[:asset].image.metadata[:asset_type]
        }
      }, content_type: 'text/html'
    else
      render json: result[:asset].errors, status: :unprocessable_entity
    end
  end

  def marvinjs_update
    asset = MarvinJsService.update_sketch(marvin_params, current_user, current_team)
    if asset
      create_edit_marvinjs_activity(asset, current_user, :finish_editing)
      render json: { url: rails_representation_url(asset.preview), id: asset.id }
    else
      render json: { error: t('marvinjs.no_sketches_found') }, status: :unprocessable_entity
    end
  end

  private

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

  def check_read_permission
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

  def check_edit_permission
    if @assoc.nil?
      if current_team == @asset.team
        return
      else
        return render_403
      end
    end
    case @assoc
    when StepText
      return render_403 unless can_manage_step?(@assoc.step)
    when Protocol
      return render_403 unless can_manage_protocol_in_module?(@protocol) ||
                               can_manage_protocol_draft_in_repository?(@protocol)
    when ResultText, MyModule
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
