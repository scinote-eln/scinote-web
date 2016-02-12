class StepsController < ApplicationController
  before_action :load_vars, only: [:edit, :update, :destroy, :show]
  before_action :load_vars_nested, only: [:new, :create]
  before_action :load_paperclip_vars
  before_action :convert_table_contents_to_utf8, only: [:create, :update]

  before_action :check_view_permissions, only: [:show]
  before_action :check_create_permissions, only: [:new, :create]
  before_action :check_edit_permissions, only: [:edit, :update]
  before_action :check_destroy_permissions, only: [:destroy]

  def new
    @step = Step.new

    respond_to do |format|
      format.json {
        render json: {
          html: render_to_string({
            partial: "new.html.erb",
            locals: {
              direct_upload: @direct_upload
            }
          })
        }
      }
    end
  end

  def create
    if @direct_upload
      step_data = step_params.except(:assets_attributes)
      step_assets = step_params.slice(:assets_attributes)
      @step = Step.new(step_data)

      if step_assets.size > 0
        step_assets[:assets_attributes].each do |i, data|
          asset = Asset.find_by_id(data[:id])
          asset.created_by = current_user
          asset.last_modified_by = current_user
          @step.assets << asset
        end
      end
    else
      @step = Step.new(step_params)
    end

    @step.completed = false
    @step.position = @my_module.number_of_steps
    @step.my_module = @my_module
    @step.user = current_user
    @step.last_modified_by = current_user

    # Update default checked state
    @step.checklists.each do |checklist|
      checklist.checklist_items.each do |checklist_item|
        checklist_item.checked = false
      end
    end

    respond_to do |format|
      if @step.save
        # Post process all assets
        @step.assets.each do |asset|
          asset.post_process_file(@my_module.project.organization)
        end

        # Generate activity
        Activity.create(
          type_of: :create_step,
          user: current_user,
          project: @my_module.project,
          my_module: @my_module,
          message: t(
            "activities.create_step",
            user: current_user.full_name,
            step: @step.position + 1,
            step_name: @step.name
          )
        )

        flash_success = t("my_modules.steps.create.success_flash", module: @my_module.name)
        format.html {
          flash[:success] = flash_success
          redirect_to steps_my_module_path(@my_module)
        }
        format.json {
          render json: {
            html: render_to_string({
              partial: "my_modules/step.html.erb", locals: {step: @step}
            })}, status: :ok
        }
      else
        format.json {
          render json: {
            html: render_to_string({
              partial: "new.html.erb",
              locals: {
                direct_upload: @direct_upload
              }
            })
          }, status: :bad_request
        }
      end
    end
  end

  def show
    respond_to do |format|
      format.json {
        render json: {
          html: render_to_string({
            partial: "my_modules/step.html.erb", locals: {step: @step}
          })}, status: :ok
      }
    end
  end

  def edit
    respond_to do |format|
      format.json {
        render json: {
          html: render_to_string({
            partial: "edit.html.erb",
            locals: {
              direct_upload: @direct_upload
            }
          })}, status: :ok
      }
    end
  end

  def update
    respond_to do |format|
      previous_size = @step.space_taken

      step_params_all = step_params

      # process only destroy update on step references. This prevents
      # skipping deleting reference in case update validation fails.
      # NOTE - step_params_all variable is updated
      destroy_attributes(step_params_all)

      if @direct_upload
        step_data = step_params_all.except(:assets_attributes)
        step_assets = step_params_all.slice(:assets_attributes)
        step_params_all = step_data

        if step_assets.include? :assets_attributes
          step_assets[:assets_attributes].each do |i, data|
            asset_id = data[:id]
            asset = Asset.find_by_id(asset_id)

            unless @step.assets.include? asset or not asset
              asset.last_modified_by = current_user
              @step.assets << asset
            end
          end
        end
      end

      @step.assign_attributes(step_params_all)
      @step.last_modified_by = current_user

      if @step.save
        @step.reload

        # Release organization's space taken
        org = @step.my_module.project.organization
        org.release_space(previous_size)
        org.save

        # Post process step assets
        @step.assets.each do |asset|
          asset.post_process_file(org)
        end

        # Generate activity
        Activity.create(
          type_of: :edit_step,
          user: current_user,
          project: @step.my_module.project,
          my_module: @step.my_module,
          message: t(
            "activities.edit_step",
            user: current_user.full_name,
            step: @step.position + 1,
            step_name: @step.name
          )
        )

        flash_success = t(
          "my_modules.steps.update.success_flash",
          step: (@step.position + 1).to_s)
        format.html {
          flash[:success] = flash_success
          redirect_to steps_my_module_path(@step.my_module)
        }
        format.json {
          render json: {
            html: render_to_string({
              partial: "my_modules/step.html.erb", locals: {step: @step}
            })}, status: :ok
        }
      else
        format.json {
          render json: {
            html: render_to_string({
              partial: "edit.html.erb",
              locals: {
                direct_upload: @direct_upload
              }
            })}, status: :bad_request
        }
      end
    end
  end

  def destroy
    # Update position on other steps of this module
    my_module = @step.my_module
    my_module.steps.where("position > ?", @step.position).each do |step|
      step.position = step.position - 1
      step.save
    end

    # Calculate space taken by this step
    org = @step.my_module.project.organization
    previous_size = @step.space_taken

    # Destroy the step
    @step.destroy(current_user)

    # Release space taken by the step
    org.release_space(previous_size)
    org.save

    flash[:success] = t(
      "my_modules.steps.destroy.success_flash",
      step: (@step.position + 1).to_s)
    redirect_to steps_my_module_path(@step.my_module)
  end

  # Responds to checkbox toggling in steps view
  def checklistitem_state
    chkItem = ChecklistItem.find_by_id(params["checklistitem_id"])

    respond_to do |format|
      if chkItem
        checked = params[:checked] == "true"
        my_module = chkItem.checklist.step.my_module

        authorized = ((checked and can_check_checkbox(my_module)) or (!checked and can_uncheck_checkbox(my_module)))

        if authorized
          changed = chkItem.checked != checked
          chkItem.checked = checked

          if chkItem.save
            format.json {
              render json: {}, status: :accepted
            }

            # Create activity
            if changed
              str = checked ? "activities.check_step_checklist_item" :
                "activities.uncheck_step_checklist_item"
              completed_items = chkItem.checklist.checklist_items.where(checked: true).count
              all_items = chkItem.checklist.checklist_items.count
              message = t(
                str,
                user: current_user.full_name,
                checkbox: chkItem.text,
                step: chkItem.checklist.step.position + 1,
                step_name: chkItem.checklist.step.name,
                completed: completed_items,
                all: all_items
              )

              Activity.create(
                user: current_user,
                project: my_module.project,
                my_module: my_module,
                message: message,
                type_of: checked ? :check_step_checklist_item : :uncheck_step_checklist_item
              )
            end
          else
            format.json {
              render json: {}, status: :unprocessable_entity
            }
          end
        else
          format.json {
            render json: {}, status: :unauthorized
          }
        end
      else
        format.json {
          render json: {}, status: :not_found
        }
      end
    end
  end

  # Complete/uncomplete step
  def toggle_step_state
    step = Step.find_by_id(params[:id])

    respond_to do |format|
      if step
        completed = params[:completed] == "true"
        my_module = step.my_module

        authorized = ((completed and can_complete_step_in_module(my_module)) or (!completed and can_uncomplete_step_in_module(my_module)))

        if authorized
          changed = step.completed != completed
          step.completed = completed

          # Update completed_on
          if changed
            step.completed_on = completed ? Time.current : nil
          end

          if step.save
            # Create activity
            if changed
              completed_steps = my_module.steps.where(completed: true).count
              all_steps = my_module.steps.count
              str = completed ? "activities.complete_step" :
                "activities.uncomplete_step"

              message = t(
                str,
                user: current_user.full_name,
                step: step.position + 1,
                step_name: step.name,
                completed: completed_steps,
                all: all_steps
              )

              Activity.create(
                user: current_user,
                project: my_module.project,
                my_module: my_module,
                message: message,
                type_of: completed ? :complete_step : :uncomplete_step
              )
            end

            # Create localized title for complete/uncomplete button
            localized_title = !completed ?
              t("my_modules.steps.options.complete_title") :
              t("my_modules.steps.options.uncomplete_title")

            format.json {
              render json: {new_title: localized_title}, status: :accepted
            }
          else
            format.json {
              render json: {}, status: :unprocessable_entity
            }
          end
        else
          format.json {
            render json: {}, status: :unauthorized
          }
        end
      else
        format.json {
          render json: {}, status: :not_found
        }
      end
    end
  end

  def move_up
    step = Step.find_by_id(params[:id])

    if step
      if can_reorder_step_in_module(step.my_module)
        if step.position > 0
          step_down = step.my_module.steps.where(position: step.position - 1).first
          step.position -= 1
          step.save

          if step_down
            step_down.position += 1
            step_down.save
          end
        end
      else
        render_403 and return
      end
    else
      render_404 and return
    end
    redirect_to steps_my_module_path(step.my_module)
  end

  def move_down
    step = Step.find_by_id(params[:id])

    if step
      if can_reorder_step_in_module(step.my_module)
        if step.position < step.my_module.steps.count - 1
          step_down = step.my_module.steps.where(position: step.position + 1).first
          step.position += 1
          step.save

          if step_down
            step_down.position -= 1
            step_down.save
          end
        end
      else
        render_403 and return
      end
    else
      render_404 and return
    end
    redirect_to steps_my_module_path(step.my_module)
  end

  private

  # This function is used for partial update of step references and
  # it's useful when you want to execute destroy action on attribute
  # collection separately from normal update action, for example if
  # you don't want that update validation interupt destroy action.
  # In case of step model you can delete checkboxes, assets or tables.
  def destroy_attributes(params)
    update_params = {}
    extract_destroy_params(params, update_params)
    @step.update_attributes(update_params) unless update_params.empty?
  end

  # Checks if hash contains destroy parameter '_destroy' and returns
  # boolean value.
  def has_destroy_params(params)
    for key, values in params do
      if values.respond_to?(:each)
        for pos, attrs in params[key] do
          return true if attrs[:_destroy] == "1"
        end
      end
    end

    false
  end

  # Extracts part of hash that contains destroy parameters. It deletes
  # values that contains destroy parameters from original variable and
  # puts them into update_params variable.
  def extract_destroy_params(params, update_params)
    for key, values in params do
      if values.respond_to?(:each)
        update_params[key] = {} unless update_params[key]
        attr_params = update_params[key]

        for pos, attrs in params[key] do
          if attrs[:_destroy] == "1"
            attr_params[pos] = {id: attrs[:id], _destroy: "1"}
            params[key].delete(pos)
          else
            if has_destroy_params(params[key][pos])
              attr_params[pos] = {id: attrs[:id]}
              extract_destroy_params(params[key][pos], attr_params[pos])
            end
          end
        end
      end
    end
  end

  def load_paperclip_vars
    @direct_upload = ENV['PAPERCLIP_DIRECT_UPLOAD']
  end

  def load_vars
    @step = Step.find_by_id(params[:id])
    @my_module = @step.my_module
    @project = @my_module.project

    unless @my_module
      render_404
    end
  end

  def load_vars_nested
    @my_module = MyModule.find_by_id(params[:my_module_id])
    @project = @my_module.project

    unless @my_module
      render_404
    end
  end

  def convert_table_contents_to_utf8
    if params.include? :step and
      params[:step].include? :tables_attributes then
      params[:step][:tables_attributes].each do |k,v|
        params[:step][:tables_attributes][k][:contents] =
          v[:contents].encode(Encoding::UTF_8).force_encoding(Encoding::UTF_8)
      end
    end
  end

  def check_view_permissions
    unless can_view_steps_in_module(@my_module)
      render_403
    end
  end

  def check_create_permissions
    unless can_create_step_in_module(@my_module)
      render_403
    end
  end

  def check_edit_permissions
    unless can_edit_step_in_module(@my_module)
      render_403
    end
  end

  def check_destroy_permissions
    unless can_delete_step_in_module(@my_module)
      render_403
    end
  end

  def step_params
    params.require(:step).permit(
      :name,
      :description,
      checklists_attributes: [
        :id,
        :name,
        :_destroy,
        checklist_items_attributes: [
          :id,
          :text,
          :position,
          :_destroy
        ]
      ],
      assets_attributes: [
        :id,
        :file,
        :_destroy
      ],
      tables_attributes: [
        :id,
        :contents,
        :_destroy
      ]
    )
  end
end
