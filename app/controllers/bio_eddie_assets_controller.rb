# frozen_string_literal: true

class BioEddieAssetsController < ApplicationController
  include ActiveStorage::SetCurrent

  before_action :load_vars, except: :create
  before_action :load_create_vars, only: :create

  before_action :check_read_permission
  before_action :check_edit_permission, only: %i(update create start_editing)

  def create
    result = BioEddieService.create_molecule(bio_eddie_params, current_user, current_team)

    if result[:asset] && bio_eddie_params[:object_type] == 'Step'
      render json: {
        html: render_to_string(partial: 'assets/asset.html.erb', locals: {
                                 asset: result[:asset],
                                 gallery_view_id: bio_eddie_params[:object_id]
                               })
      }
    elsif result[:asset] && bio_eddie_params[:object_type] == 'Result'
      @my_module = result[:object].my_module
      render json: {
        html: render_to_string(
          partial: 'my_modules/result.html.erb',
            locals: { result: result[:object] }
        )
      }, status: :ok
    else
      render json: result[:asset].errors, status: :unprocessable_entity
    end
  end

  def update
    asset = BioEddieService.update_molecule(bio_eddie_params, current_user, current_team)

    if asset
      render json: { url: rails_representation_url(asset.medium_preview),
                     id: asset.id,
                     file_name: asset.blob.metadata['name'] }
    else
      render json: { error: t('marvinjs.no_sketches_found') }, status: :unprocessable_entity
    end
  end

  def start_editing
    # Activity here
  end

  private

  def load_vars
    @asset = current_team.assets.find_by(id: params[:id])
    return render_404 unless @asset

    @assoc ||= @asset.step
    @assoc ||= @asset.result

    if @assoc.instance_of?(Step)
      @protocol = @assoc.protocol
    elsif @assoc.instance_of?(Result)
      @my_module = @assoc.my_module
    end
  end

  def load_create_vars
    @assoc = Step.find_by(id: bio_eddie_params[:object_id]) if bio_eddie_params[:object_type] == 'Step'
    @assoc = MyModule.find_by(id: bio_eddie_params[:object_id]) if bio_eddie_params[:object_type] == 'Result'

    if @assoc.instance_of?(Step)
      @protocol = @assoc.protocol
    elsif @assoc.instance_of?(MyModule)
      @my_module = @assoc
    end
  end

  def check_read_permission
    if @assoc.instance_of?(Step)
      return render_403 unless can_read_protocol_in_module?(@protocol) ||
                               can_read_protocol_in_repository?(@protocol)
    elsif @assoc.instance_of?(Result) || @assoc.instance_of?(MyModule)
      return render_403 unless can_read_experiment?(@my_module.experiment)
    else
      render_403
    end
  end

  def check_edit_permission
    if @assoc.instance_of?(Step)
      return render_403 unless can_manage_protocol_in_module?(@protocol) ||
                               can_manage_protocol_in_repository?(@protocol)
    elsif @assoc.instance_of?(Result) || @assoc.instance_of?(MyModule)
      return render_403 unless can_manage_module?(@my_module)
    else
      render_403
    end
  end

  def bio_eddie_params
    params.permit(:id, :description, :object_id, :object_type, :name, :image)
  end
end
