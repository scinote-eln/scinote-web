class ResultTextsController < ApplicationController
  include ResultsHelper
  include ActionView::Helpers::UrlHelper
  include ApplicationHelper
  include TinyMceHelper
  include InputSanitizeHelper
  include Rails.application.routes.url_helpers

  before_action :load_vars, only: [:edit, :update, :download]
  before_action :load_vars_nested, only: [:new, :create]

  before_action :check_manage_permissions, only: %i(new create edit update)
  before_action :check_archive_permissions, only: [:update]

  def new
    @result = Result.new(
      user: current_user,
      my_module: @my_module
    )
    @result.build_result_text

    respond_to do |format|
      format.json {
        render json: {
          html: render_to_string({
            partial: "new.html.erb"
          })
        }, status: :ok
      }
    end
  end

  def create
    @result_text = ResultText.new(result_params[:result_text_attributes])
    # gerate a tag that replaces img tag in database
    @result_text.text = parse_tiny_mce_asset_to_token(@result_text.text,
                                                      @result_text)
    @result = Result.new(
      user: current_user,
      my_module: @my_module,
      name: result_params[:name],
      result_text: @result_text
    )
    @result.last_modified_by = current_user

    respond_to do |format|
      if @result.save && @result_text.save
        # link tiny_mce_assets to the text result
        link_tiny_mce_assets(@result_text.text, @result_text)

        result_annotation_notification
        # Generate activity
        Activity.create(
          type_of: :add_result,
          user: current_user,
          project: @my_module.experiment.project,
          experiment: @my_module.experiment,
          my_module: @my_module,
          message: t(
            "activities.add_text_result",
            user: current_user.full_name,
            result: @result.name
          )
        )

        format.html {
          flash[:success] = t(
            "result_texts.create.success_flash",
            module: @my_module.name)
          redirect_to results_my_module_path(@my_module)
        }
        format.json {
          render json: {
            html: render_to_string({
              partial: "my_modules/result.html.erb",
              locals: {
                result: @result
              }
            })
          }, status: :ok
        }
      else
        format.json {
          render json: @result.errors, status: :bad_request
        }
      end
    end
  end

  def edit
    @result_text.text = generate_image_tag_from_token(@result_text.text,
                                                      @result_text)
    respond_to do |format|
      format.json {
        render json: {
          html: render_to_string({
            partial: "edit.html.erb"
          })
        }, status: :ok
      }
    end
  end

  def update
    old_text = @result_text.text
    update_params = result_params
    @result.last_modified_by = current_user
    @result.assign_attributes(update_params)
    @result_text.text = parse_tiny_mce_asset_to_token(@result_text.text,
                                                      @result_text)
    success_flash = t("result_texts.update.success_flash",
            module: @my_module.name)
    if @result.archived_changed?(from: false, to: true)
      saved = @result.archive(current_user)
      success_flash = t("result_texts.archive.success_flash",
            module: @my_module.name)
      if saved
        Activity.create(
          type_of: :archive_result,
          project: @my_module.experiment.project,
          experiment: @my_module.experiment,
          my_module: @my_module,
          user: current_user,
          message: t(
            'activities.archive_text_result',
            user: current_user.full_name,
            result: @result.name
          )
        )
      end
    elsif @result.archived_changed?(from: true, to: false)
      render_403
    else
      saved = @result.save

      if saved then
        Activity.create(
          type_of: :edit_result,
          user: current_user,
          project: @my_module.experiment.project,
          experiment: @my_module.experiment,
          my_module: @my_module,
          message: t(
            "activities.edit_text_result",
            user: current_user.full_name,
            result: @result.name
          )
        )
      end
    end

    result_annotation_notification(old_text) if saved

    respond_to do |format|
      if saved
        format.html {
          flash[:success] = success_flash
          redirect_to results_my_module_path(@my_module)
        }
        format.json {
          render json: {
            html: render_to_string({
              partial: "my_modules/result.html.erb",
              locals: {
                result: @result
              }
            })
          }, status: :ok
        }
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

  def load_vars_nested
    @my_module = MyModule.find_by_id(params[:my_module_id])

    unless @my_module
      render_404
    end
  end

  def check_manage_permissions
    render_403 unless can_manage_module?(@my_module)
  end

  def check_archive_permissions
    if result_params[:archived].to_s != '' && !can_manage_result?(@result)
      render_403
    end
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
      title: t('notifications.result_annotation_title',
               result: @result.name,
               user: current_user.full_name),
      message: t('notifications.result_annotation_message_html',
                 project: link_to(@result.my_module.experiment.project.name,
                                  project_url(@result.my_module
                                                   .experiment
                                                   .project)),
                 experiment: link_to(@result.my_module.experiment.name,
                                     canvas_experiment_url(@result.my_module
                                                                  .experiment)),
                 my_module: link_to(@result.my_module.name,
                                    protocols_my_module_url(
                                      @result.my_module
                                    )))
    )
  end
end
