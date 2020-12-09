# frozen_string_literal: true

class MarvinJsAssetsController < ApplicationController
  include MarvinJsActions
<<<<<<< HEAD
<<<<<<< HEAD
  include ActiveStorage::SetCurrent
=======
>>>>>>> Initial commit of 1.17.2 merge
=======
  include ActiveStorage::SetCurrent
>>>>>>> Pulled latest release

  before_action :load_vars, except: :create
  before_action :load_create_vars, only: :create

  before_action :check_read_permission
  before_action :check_edit_permission, only: %i(update create start_editing)

  def create
    result = MarvinJsService.create_sketch(marvin_params, current_user, current_team)

    create_create_marvinjs_activity(result[:asset], current_user)

    if result[:asset] && marvin_params[:object_type] == 'Step'
      render json: {
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> Pulled latest release
        html: render_to_string(partial: 'assets/asset.html.erb', locals: {
                                 asset: result[:asset],
                                 gallery_view_id: marvin_params[:object_id]
                               })
<<<<<<< HEAD
=======
        html: render_to_string(
          partial: 'steps/attachments/item.html.erb',
             locals: { asset: result[:asset],
                       i: 0,
                       assets_count: 0,
                       step: result[:object],
                       order_atoz: 0,
                       order_ztoa: 0 }
        )
>>>>>>> Initial commit of 1.17.2 merge
=======
>>>>>>> Pulled latest release
      }
    elsif result[:asset] && marvin_params[:object_type] == 'Result'
      @my_module = result[:object].my_module
      render json: {
        html: render_to_string(
          partial: 'my_modules/result.html.erb',
            locals: { result: result[:object] }
        )
      }, status: :ok
    elsif result[:asset]
      render json: result[:asset]
    else
      render json: result[:asset].errors, status: :unprocessable_entity
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
<<<<<<< HEAD
<<<<<<< HEAD
    @asset = current_team.assets.find_by(id: params[:id])
=======
    @asset = current_team.assets.find_by_id(params[:id])
>>>>>>> Initial commit of 1.17.2 merge
=======
    @asset = current_team.assets.find_by(id: params[:id])
>>>>>>> Pulled latest release
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
<<<<<<< HEAD
<<<<<<< HEAD
    @assoc = Step.find_by(id: marvin_params[:object_id]) if marvin_params[:object_type] == 'Step'
    @assoc = MyModule.find_by(id: params[:object_id]) if marvin_params[:object_type] == 'Result'
=======
    @assoc = Step.find_by_id(marvin_params[:object_id]) if marvin_params[:object_type] == 'Step'
    @assoc = MyModule.find_by_id(params[:object_id]) if marvin_params[:object_type] == 'Result'
>>>>>>> Initial commit of 1.17.2 merge
=======
    @assoc = Step.find_by(id: marvin_params[:object_id]) if marvin_params[:object_type] == 'Step'
    @assoc = MyModule.find_by(id: params[:object_id]) if marvin_params[:object_type] == 'Result'
>>>>>>> Pulled latest release

    if @assoc.class == Step
      @protocol = @assoc.protocol
    elsif @assoc.class == MyModule
      @my_module = @assoc
    end
  end

  def check_read_permission
    if @assoc.class == Step
      return render_403 unless can_read_protocol_in_module?(@protocol) ||
                               can_read_protocol_in_repository?(@protocol)
    elsif @assoc.class == Result || @assoc.class == MyModule
      return render_403 unless can_read_experiment?(@my_module.experiment)
    else
      render_403
    end
  end

  def check_edit_permission
    if @assoc.class == Step
<<<<<<< HEAD
      return render_403 unless can_manage_step?(@assoc)
    elsif @assoc.class == Result || @assoc.class == MyModule
      return render_403 unless can_manage_my_module?(@my_module)
=======
      return render_403 unless can_manage_protocol_in_module?(@protocol) ||
                               can_manage_protocol_in_repository?(@protocol)
    elsif @assoc.class == Result || @assoc.class == MyModule
      return render_403 unless can_manage_module?(@my_module)
>>>>>>> Initial commit of 1.17.2 merge
    else
      render_403
    end
  end

  def marvin_params
    params.permit(:id, :description, :object_id, :object_type, :name, :image)
  end
end
