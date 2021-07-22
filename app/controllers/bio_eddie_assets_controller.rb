# frozen_string_literal: true

class BioEddieAssetsController < ApplicationController
  include BioEddieActions
  include ActiveStorage::SetCurrent

  before_action :load_vars, except: :create
  before_action :load_create_vars, only: :create

  before_action :check_read_permission
  before_action :check_edit_permission, only: %i(update create start_editing)

  def create
    asset = BioEddieService.create_molecule(bio_eddie_params, current_user, current_team)

    create_create_bio_eddie_activity(asset, current_user)

    if asset && bio_eddie_params[:object_type] == 'Step'
      render json: {
        html: render_to_string(partial: 'assets/asset.html.erb', locals: {
                                 asset: asset,
                                 gallery_view_id: bio_eddie_params[:object_id]
                               })
      }
    elsif asset && bio_eddie_params[:object_type] == 'Result'
      log_registration_activity(asset) if bio_eddie_params[:schedule_for_registration] == 'true'
      render json: { status: 'created' }, status: :ok
    else
      render json: asset.errors, status: :unprocessable_entity
    end
  end

  def update
    asset = BioEddieService.update_molecule(bio_eddie_params, current_user, current_team)

    create_edit_bio_eddie_activity(asset, current_user, :finish_editing)

    if asset
      log_registration_activity(asset) if bio_eddie_params[:schedule_for_registration] == 'true'
      render json: { url: rails_representation_url(asset.medium_preview),
                     id: asset.id,
                     file_name: asset.blob.metadata['name'] }
    else
      render json: { error: t('bio_eddie.no_molecules_found') }, status: :unprocessable_entity
    end
  end

  def start_editing
    create_edit_bio_eddie_activity(@asset, current_user, :start_editing)
  end

  private

  def load_vars
    @asset = current_team.assets.find_by(id: params[:id])
    return render_404 unless @asset

    @assoc = @asset.step || @asset.result

    case @assoc
    when Step
      @protocol = @assoc.protocol
    when Result
      @my_module = @assoc.my_module
    end
  end

  def load_create_vars
    case bio_eddie_params[:object_type]
    when 'Step'
      @assoc = Step.find_by(id: bio_eddie_params[:object_id])
      @protocol = @assoc.protocol
    when 'Result'
      @assoc = MyModule.find_by(id: bio_eddie_params[:object_id])
      @my_module = @assoc
    end
  end

  def check_read_permission
    case @assoc
    when Step
      return render_403 unless can_read_protocol_in_module?(@protocol) ||
                               can_read_protocol_in_repository?(@protocol)
    when Result, MyModule
      return render_403 unless can_read_experiment?(@my_module.experiment)
    else
      render_403
    end
  end

  def check_edit_permission
    case @assoc
    when Step
      return render_403 unless can_manage_protocol_in_module?(@protocol) ||
                               can_manage_protocol_in_repository?(@protocol)
    when Result, MyModule
      return render_403 unless can_manage_module?(@my_module)
    else
      render_403
    end
  end

  def bio_eddie_params
    params.permit(:id, :description, :object_id, :object_type, :name, :image, :schedule_for_registration)
  end

  def log_registration_activity(asset)
    Activities::CreateActivityService
      .call(
        activity_type: :register_molecule,
        owner: current_user,
        team: asset.team,
        project: asset.my_module.experiment.project,
        subject: asset,
        message_items: {
          description: asset.blob.metadata['description'],
          name: asset.blob.metadata['name']
        }
      )
  end
end
