# frozen_string_literal: true

class MarvinJsAssetsController < ApplicationController
  include MarvinJsActions
  include ActiveStorage::SetCurrent

  before_action :load_vars, except: :create
  before_action :load_create_vars, only: :create

  before_action :check_read_permission
  before_action :check_edit_permission, only: %i(update create start_editing)

  def create
    result = MarvinJsService.create_sketch(marvin_params, current_user, current_team)

    create_create_marvinjs_activity(result[:asset], current_user)

    if result[:asset]
      if marvin_params[:object_type] == 'Step' || marvin_params[:object_type] == 'Result'
        render json: {
          html: render_to_string(partial: 'assets/asset', locals: {
                                   asset: result[:asset],
                                   gallery_view_id: marvin_params[:object_id]
                                 })
        }
      else
        render json: result[:asset]
      end
    else
      render json: result[:asset]&.errors, status: :unprocessable_entity
    end
  end

  def update
    asset = MarvinJsService.update_sketch(marvin_params, current_user, current_team)

    create_edit_marvinjs_activity(asset, current_user, :finish_editing)

    if asset
      render json: { url: rails_representation_url(asset.medium_preview),
                     id: asset.id,
                     file_name: asset.blob.metadata['name'] }
    else
      render json: { error: t('marvinjs.no_sketches_found') }, status: :unprocessable_entity
    end
  end

  def start_editing
    create_edit_marvinjs_activity(@asset, current_user, :start_editing)
  end

  private

  def load_vars
    @asset = current_team.assets.find_by(id: params[:id])
    return render_404 unless @asset

    @assoc ||= @asset.step
    @assoc ||= @asset.result

    if @assoc.class == Step
      @protocol = @assoc.protocol
    elsif @assoc.class == Result
      @my_module = @assoc.my_module
    end
  end

  def load_create_vars
    @assoc = Step.find_by(id: marvin_params[:object_id]) if marvin_params[:object_type] == 'Step'
    @assoc = Result.find_by(id: params[:object_id]) if marvin_params[:object_type] == 'Result'

    if @assoc.class == Step
      @protocol = @assoc.protocol
    elsif @assoc.class == Result
      @my_module = @assoc.my_module
    end
  end

  def check_read_permission
    if @assoc.class == Step
      return render_403 unless can_read_protocol_in_module?(@protocol) ||
                               can_read_protocol_in_repository?(@protocol)
    elsif @assoc.class == Result
      return render_403 unless can_read_experiment?(@my_module.experiment)
    else
      render_403
    end
  end

  def check_edit_permission
    if @assoc.class == Step
      return render_403 unless can_manage_step?(@assoc)
    elsif @assoc.class == Result
      return render_403 unless can_manage_my_module?(@assoc.my_module)
    else
      render_403
    end
  end

  def marvin_params
    params.permit(:id, :description, :object_id, :object_type, :name, :image)
  end
end
