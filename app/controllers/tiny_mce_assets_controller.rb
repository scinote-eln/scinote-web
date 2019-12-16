# frozen_string_literal: true

class TinyMceAssetsController < ApplicationController
  include MarvinJsActions
  include ActiveStorage::SetCurrent

  before_action :load_vars, only: %i(marvinjs_show marvinjs_update download)

  before_action :check_read_permission, only: %i(marvinjs_show marvinjs_update download)
  before_action :check_edit_permission, only: %i(marvinjs_update)

  def create
    image = params.fetch(:file) { render_404 }
    unless image.content_type.match?(%r{^image/#{Regexp.union(Constants::WHITELISTED_IMAGE_TYPES)}})
      return render json: {
        errors: [I18n.t('tiny_mce.unsupported_image_format')]
      }, status: :unprocessable_entity
    end

    tiny_img = TinyMceAsset.new(team_id: current_team.id, saved: false)

    tiny_img.transaction do
      tiny_img.save!
      tiny_img.image.attach(io: image, filename: image.original_filename)
    end

    if tiny_img.persisted?
      render json: {
        image: {
          url: url_for(tiny_img.image),
          token: Base62.encode(tiny_img.id)
        }
      }, content_type: 'text/html'
    else
      render json: {
        errors: tiny_img.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def download
    if @asset&.image&.attached?
      redirect_to rails_blob_path(@asset.image, disposition: 'attachment')
    else
      render_404
    end
  end

  def marvinjs_show
    asset = current_team.tiny_mce_assets.find_by_id(Base62.decode(params[:id]))
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
    @asset = current_team.tiny_mce_assets.find_by_id(Base62.decode(params[:id]))
    return render_404 unless @asset

    @assoc = @asset.object

    if @assoc.class == Step
      @protocol = @assoc.protocol
    elsif @assoc.class == Protocol
      @protocol = @assoc
    elsif @assoc.class == MyModule
      @my_module = @assoc
    elsif @assoc.class == ResultText
      @my_module = @assoc.result.my_module
    end
  end

  def check_read_permission
    if @assoc.class == Step || @assoc.class == Protocol
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
    if @assoc.class == Step || @assoc.class == Protocol
      return render_403 unless can_manage_protocol_in_module?(@protocol) ||
                               can_manage_protocol_in_repository?(@protocol)
    elsif @assoc.class == ResultText || @assoc.class == MyModule
      return render_403 unless can_manage_module?(@my_module)
    elsif @assoc.nil?
      return render_403 unless current_team == @asset.team
    else
      render_403
    end
  end

  def marvin_params
    params.permit(:id, :description, :object_id, :object_type, :name, :image)
  end
end
