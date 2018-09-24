class StepsController < ApplicationController
  include ActionView::Helpers::TextHelper
  include ApplicationHelper
  include TinyMceHelper
  include StepsActions

  before_action :load_vars, only: %i(edit update destroy show toggle_step_state
                                     checklistitem_state)
  before_action :load_vars_nested, only: [:new, :create]
  before_action :convert_table_contents_to_utf8, only: [:create, :update]

  before_action :check_view_permissions, only: [:show]
  before_action :check_manage_permissions, only: %i(new create edit update
                                                    destroy)
  before_action :check_complete_and_checkbox_permissions, only:
    %i(toggle_step_state checklistitem_state)

  before_action :update_checklist_item_positions, only: [:create, :update]

  def new
    @step = Step.new

    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(partial: 'new.html.erb')
        }
      end
    end
  end

  def create
    @step = Step.new(step_params)
    # gerate a tag that replaces img tag in database
    @step.description = parse_tiny_mce_asset_to_token(@step.description, @step)
    @step.completed = false
    @step.position = @protocol.number_of_steps
    @step.protocol = @protocol
    @step.user = current_user
    @step.last_modified_by = current_user
    @step.assets.each do |asset|
      asset.created_by = current_user
      asset.team = current_team
    end
    @step.tables.each do |table|
      table.created_by = current_user
      table.team = current_team
    end
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
          asset.post_process_file(@protocol.team)
        end

        # link tiny_mce_assets to the step
        link_tiny_mce_assets(@step.description, @step)

        create_annotation_notifications(@step)

        # Generate activity
        if @protocol.in_module?
          Activity.create(
            type_of: :create_step,
            user: current_user,
            project: @my_module.experiment.project,
            experiment: @my_module.experiment,
            my_module: @my_module,
            message: t(
              "activities.create_step",
              user: current_user.full_name,
              step: @step.position + 1,
              step_name: @step.name
            )
          )
        else
          # TODO: Activity for team if step
          # created in protocol management??
        end

        # Update protocol timestamp
        update_protocol_ts(@step)

        format.json do
          render json: {
            html: render_to_string(
              partial: 'steps/step.html.erb',
                       locals: { step: @step }
            )
          },
          status: :ok
        end
      else
        format.json do
          render json: @step.errors.to_json, status: :bad_request
        end
      end
    end
  end

  def show
    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(
            partial: 'steps/step.html.erb',
                     locals: { step: @step }
          )
        },
        status: :ok
      end
    end
  end

  def edit
    @step.description = generate_image_tag_from_token(@step.description, @step)
    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(partial: 'edit.html.erb')
        },
        status: :ok
      end
    end
  end

  def update
    respond_to do |format|
      old_description = @step.description
      old_checklists = fetch_old_checklists_data(@step)
      new_checklists = fetch_new_checklists_data
      previous_size = @step.space_taken

      step_params_all = step_params

      # process only destroy update on step references. This prevents
      # skipping deleting reference in case update validation fails.
      # NOTE - step_params_all variable is updated
      destroy_attributes(step_params_all)

      @step.assign_attributes(step_params_all)
      @step.last_modified_by = current_user

      @step.assets.each do |asset|
        asset.created_by = current_user if asset.new_record?
        asset.last_modified_by = current_user unless asset.new_record?
        asset.team = current_team
      end

      @step.tables.each do |table|
        table.created_by = current_user if table.new_record?
        table.last_modified_by = current_user unless table.new_record?
        table.team = current_team
      end

      # gerate a tag that replaces img tag in databases
      @step.description = parse_tiny_mce_asset_to_token(
        params[:step][:description],
        @step
      )

      if @step.save
        @step.reload

        # generates notification on step upadate
        update_annotation_notifications(@step,
                                        old_description,
                                        new_checklists,
                                        old_checklists)

        # Release team's space taken
        team = @protocol.team
        team.release_space(previous_size)
        team.save

        # Post process step assets
        @step.assets.each do |asset|
          asset.post_process_file(team)
        end

        # Generate activity
        if @protocol.in_module?
          Activity.create(
            type_of: :edit_step,
            user: current_user,
            project: @my_module.experiment.project,
            experiment: @my_module.experiment,
            my_module: @my_module,
            message: t(
              "activities.edit_step",
              user: current_user.full_name,
              step: @step.position + 1,
              step_name: @step.name
            )
          )
        else
          # TODO: Activity for team if step
          # updated in protocol management??
        end

        # Update protocol timestamp
        update_protocol_ts(@step)

        format.json {
          render json: {
            html: render_to_string({
                partial: 'step.html.erb',
                locals: { step:  @step }
                })
          }
        }
      else
        format.json {
          render json: @step.errors.to_json, status: :bad_request
        }
      end
    end
  end

  def destroy
    if @step.can_destroy?
      # Update position on other steps of this module
      @protocol.steps.where('position > ?', @step.position).each do |step|
        step.position = step.position - 1
        step.save
      end

      # Calculate space taken by this step
      team = @protocol.team
      previous_size = @step.space_taken

      # Destroy the step
      @step.destroy(current_user)

      # Release space taken by the step
      team.release_space(previous_size)
      team.save

      # Update protocol timestamp
      update_protocol_ts(@step)

      flash[:success] = t(
        'protocols.steps.destroy.success_flash',
        step: (@step.position + 1).to_s
      )
    else
      flash[:error] = t(
        'protocols.steps.destroy.error_flash',
        step: (@step.position + 1).to_s
      )
    end

    if @protocol.in_module?
      redirect_to protocols_my_module_path(@step.my_module)
    else
      redirect_to edit_protocol_path(@protocol)
    end
  end

  # Responds to checkbox toggling in steps view
  def checklistitem_state
    respond_to do |format|
      checked = params[:checked] == 'true'
      changed = @chk_item.checked != checked
      @chk_item.checked = checked

      if @chk_item.save
        format.json { render json: {}, status: :accepted }

        # Create activity
        if changed
          str = if checked
                  'activities.check_step_checklist_item'
                else
                  'activities.uncheck_step_checklist_item'
                end
          completed_items = @chk_item.checklist.checklist_items
                                     .where(checked: true).count
          all_items = @chk_item.checklist.checklist_items.count
          text_activity = smart_annotation_parser(@chk_item.text)
                          .gsub(/\s+/, ' ')
          message = t(
            str,
            user: current_user.full_name,
            checkbox: text_activity,
            step: @chk_item.checklist.step.position + 1,
            step_name: @chk_item.checklist.step.name,
            completed: completed_items,
            all: all_items
          )

          # This should always hold true (only in module can
          # check items be checked, but still check just in case)
          if @protocol.in_module?
            Activity.create(
              user: current_user,
              project: @protocol.my_module.experiment.project,
              experiment: @protocol.my_module.experiment,
              my_module: @protocol.my_module,
              message: message,
              type_of: if checked
                         :check_step_checklist_item
                       else
                         :uncheck_step_checklist_item
                       end
            )
          end
        end
      else
        format.json { render json: {}, status: :unprocessable_entity }
      end
    end
  end

  # Complete/uncomplete step
  def toggle_step_state
    respond_to do |format|
      completed = params[:completed] == 'true'
      changed = @step.completed != completed
      @step.completed = completed

      # Update completed_on
      if changed
        @step.completed_on = completed ? Time.current : nil
      end

      if @step.save
        if @protocol.in_module?
          ready_to_complete = @protocol.my_module.check_completness_status
        end

        # Create activity
        if changed
          completed_steps = @protocol.steps.where(completed: true).count
          all_steps = @protocol.steps.count
          str = 'activities.uncomplete_step'
          str = 'activities.complete_step' if completed

          message = t(
            str,
            user: current_user.full_name,
            step: @step.position + 1,
            step_name: @step.name,
            completed: completed_steps,
            all: all_steps
          )

          # Toggling step state can only occur in
          # module protocols, so my_module is always
          # not nil; nonetheless, check if my_module is present
          if @protocol.in_module?
            Activity.create(
              user: current_user,
              project: @protocol.my_module.experiment.project,
              experiment: @protocol.my_module.experiment,
              my_module: @protocol.my_module,
              message: message,
              type_of: completed ? :complete_step : :uncomplete_step
            )
          end
        end

        # Create localized title for complete/uncomplete button
        localized_title = if !completed
                            t('protocols.steps.options.complete_title')
                          else
                            t('protocols.steps.options.uncomplete_title')
                          end
        format.json do
          if ready_to_complete && @protocol.my_module.uncompleted?
            render json: {
              task_ready_to_complete: true,
              new_title: localized_title
            }, status: :ok
          else
            render json: { new_title: localized_title }, status: :ok
          end
        end
      else
        format.json { render json: {}, status: :unprocessable_entity }
      end
    end
  end

  def move_up
    step = Step.find_by_id(params[:id])

    respond_to do |format|
      if step
        protocol = step.protocol
        if can_manage_protocol_in_module?(protocol) ||
           can_manage_protocol_in_repository?(protocol)
          if step.position > 0
            step_down = step.protocol.steps.where(position: step.position - 1).first
            step.position -= 1
            step.save

            if step_down
              step_down.position += 1
              step_down.save

              # Update protocol timestamp
              update_protocol_ts(step)

              format.json {
                render json: { move_direction: "up", step_up_position: step.position, step_down_position: step_down.position },
                status: :ok
              }
            else
              format.json {
              render json: {}, status: :forbidden
            }
            end
          else
            format.json {
              render json: {}, status: :forbidden
            }
          end
        else
          format.json {
              render json: {}, status: :forbidden
            }
        end
      else
        format.json {
          render json: {}, status: :not_found
        }
      end
    end
  end

  def move_down
    step = Step.find_by_id(params[:id])

    respond_to do |format|
      if step
        protocol = step.protocol
        if can_manage_protocol_in_module?(protocol) ||
           can_manage_protocol_in_repository?(protocol)
          if step.position < step.protocol.steps.count - 1
            step_up = step.protocol.steps.where(position: step.position + 1).first
            step.position += 1
            step.save

            if step_up
              step_up.position -= 1
              step_up.save

              # Update protocol timestamp
              update_protocol_ts(step)

              format.json {
                render json: { move_direction: "down", step_up_position: step_up.position, step_down_position: step.position },
                status: :ok
              }
            else
              format.json {
                render json: {}, status: :forbidden
              }
            end
          else
            format.json {
              render json: {}, status: :forbidden
            }
          end
        else
          format.json {
            render json: {}, status: :forbidden
          }
        end
      else
        format.json {
          render json: {}, status: :not_found
        }
      end
    end
  end

  private

  def update_checklist_item_positions
    if params["step"].present? && params["step"]["checklists_attributes"].present?
      params["step"]["checklists_attributes"].values.each do |cla|
        if cla["checklist_items_attributes"].present?
          cla["checklist_items_attributes"].each do |idx, item|
            item["position"] = idx
          end
        end
      end
    end
  end

  # This function is used for partial update of step references and
  # it's useful when you want to execute destroy action on attribute
  # collection separately from normal update action, for example if
  # you don't want that update validation interupt destroy action.
  # In case of step model you can delete checkboxes, assets or tables.
  def destroy_attributes(params)
    update_params = {}
    delete_step_tables(params)
    extract_destroy_params(params, update_params)
    @step.update_attributes(update_params) unless update_params.empty?
  end

  # Delete the step table
  def delete_step_tables(params)
    return unless params[:tables_attributes].present?
    params[:tables_attributes].each do |_, table|
      next unless table['_destroy']
      table_to_destroy = Table.find_by_id(table['id'])
      next if table_to_destroy.nil?
      table_to_destroy.report_elements.destroy_all
    end
  end

  # Checks if hash contains destroy parameter '_destroy' and returns
  # boolean value.
  def has_destroy_params(params)
    for key, values in params do
      if values.respond_to?(:each)
        for pos, attrs in params[key] do
          if attrs[:_destroy] == '1'
            return true
          end
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
          if attrs[:_destroy] == '1'
            if attrs[:id].present?
              asset = Asset.find_by_id(attrs[:id])
              if asset.try(&:locked?)
                asset.errors.add(:base, 'This file is locked.')
              else
                attr_params[pos] = { id: attrs[:id], _destroy: '1' }
              end
            end
            params[key].delete(pos)
          elsif has_destroy_params(params[key][pos])
            attr_params[pos] = { id: attrs[:id] }
            extract_destroy_params(params[key][pos], attr_params[pos])
          end
        end
      end
    end
  end

  def load_vars
    @step = Step.find_by_id(params[:id])
    @protocol = @step.protocol
    if params[:checklistitem_id]
      @chk_item = ChecklistItem.find_by_id(params[:checklistitem_id])
    end

    unless @protocol
      render_404
    end

    if @protocol.in_module?
      @my_module = @protocol.my_module
    end
  end

  def load_vars_nested
    @protocol = Protocol.find_by_id(params[:protocol_id])

    unless @protocol
      render_404
    end

    if @protocol.in_module?
      @my_module = @protocol.my_module
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

  def update_protocol_ts(step)
    if step.present? && step.protocol.present?
      step.protocol.update(updated_at: Time.now)
    end
  end

  def check_view_permissions
    render_403 unless can_read_protocol_in_module?(@protocol) ||
                      can_read_protocol_in_repository?(@protocol)
  end

  def check_manage_permissions
    render_403 unless can_manage_protocol_in_module?(@protocol) ||
                      can_manage_protocol_in_repository?(@protocol)
  end

  def check_complete_and_checkbox_permissions
    render_403 unless can_complete_or_checkbox_step?(@protocol)
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
        :name,
        :contents,
        :_destroy
      ]
    )
  end
end
