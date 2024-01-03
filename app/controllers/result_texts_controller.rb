class ResultTextsController < ApplicationController
  include ResultsHelper
  include ActionView::Helpers::UrlHelper
  include ApplicationHelper
  include InputSanitizeHelper
  include Rails.application.routes.url_helpers

  before_action :load_vars, only: [:edit, :update, :download]

  before_action :check_manage_permissions, only: %i(edit update)
  before_action :check_archive_permissions, only: [:update]
  before_action :check_view_permissions, except: %i(edit update)

  def edit
    render json: {
      html: render_to_string({ partial: 'edit', formats: :html })
    }, status: :ok
  end

  def update
    old_text = @result_text.text
    update_params = result_params
    @result.last_modified_by = current_user
    @result.assign_attributes(update_params)

    success_flash = t("result_texts.update.success_flash",
            module: @my_module.name)
    if @result.archived_changed?(from: false, to: true)
      saved = @result.archive(current_user)
      success_flash = t("result_texts.archive.success_flash",
            module: @my_module.name)
      if saved

        log_activity(:archive_result)

        TinyMceAsset.update_images(@result_text, params[:tiny_mce_images], current_user)

      end
    elsif @result.archived_changed?(from: true, to: false)
      render_403
    else
      saved = @result.save

      if saved then

        log_activity(:edit_result)

        TinyMceAsset.update_images(@result_text, params[:tiny_mce_images], current_user)

      end
    end

    result_annotation_notification(old_text) if saved

    respond_to do |format|
      if saved
        format.html do
          flash[:success] = success_flash
          redirect_to results_my_module_path(@my_module)
        end
        format.json do
          render json: {
            html: render_to_string(
              partial: 'my_modules/result',
              locals: { result: @result },
              formats: :html
            )
          }
        end
      else
        format.json {
          render json: @result.errors, status: :bad_request
        }
      end
    end
  end

  def download
    send_data @result_text.text, filename: @result_text.result.name + '.txt',
      type: 'plain/text'
  end

  private

  def load_vars
    @result_text = ResultText.find_by_id(params[:id])

    if @result_text
      @result = @result_text.result
      @my_module = @result.my_module
    else
      render_404
    end
  end

  def check_manage_permissions
    render_403 unless can_manage_result?(@result)
  end

  def check_archive_permissions
    if result_params[:archived].to_s != '' && !can_manage_result?(@result)
      render_403
    end
  end

  def check_view_permissions
    render_403 unless can_read_result?(@result)
  end

  def result_params
    params.require(:result).permit(
      :name, :archived,
      result_text_attributes: [
        :id,
        :text
      ]
    )
  end

  def result_annotation_notification(old_text = nil)
    smart_annotation_notification(
      old_text: (old_text if old_text),
      new_text: @result_text.text,
      subject: @result,
      title: t('notifications.result_annotation_title',
               result: @result.name,
               user: current_user.full_name),
      message: t('notifications.result_annotation_message_html',
                 project: link_to(@result.my_module.experiment.project.name,
                                  project_url(@result.my_module
                                                   .experiment
                                                   .project)),
                 experiment: link_to(@result.my_module.experiment.name,
                                     my_modules_experiment_url(@result.my_module
                                                                      .experiment)),
                 my_module: link_to(@result.my_module.name,
                                    protocols_my_module_url(
                                      @result.my_module
                                    )))
    )
  end

  def log_activity(type_of)
    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            subject: @result,
            team: @my_module.team,
            project: @my_module.project,
            message_items: {
              result: @result.id,
              type_of_result: t('activities.result_type.text')
            })
  end
end
