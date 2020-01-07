class StepsController < ApplicationController
  include ActionView::Helpers::TextHelper
  include ApplicationHelper
  include StepsActions
  include MarvinJsActions

  before_action :load_vars, only: %i(edit update destroy show toggle_step_state checklistitem_state update_view_state)
  before_action :load_vars_nested, only: [:new, :create]
  before_action :convert_table_contents_to_utf8, only: [:create, :update]

  before_action :check_view_permissions, only: %i(show update_view_state)
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
    @step = Step.new
    @step.transaction do
      new_step_params = step_params

      # Attach newly uploaded files, and than remove their blob ids from the parameters
      new_step_params[:assets_attributes]&.each do |key, value|
        next unless value[:signed_blob_id]

        asset = Asset.create!(created_by: current_user, last_modified_by: current_user, team: current_team)
        asset.file.attach(value[:signed_blob_id])
        @step.assets << asset
        new_step_params[:assets_attributes].delete(key)
      end

      @step.assign_attributes(new_step_params)
      # gerate a tag that replaces img tag in database
      @step.completed = false
      @step.position = @protocol.number_of_steps
      @step.protocol = @protocol
      @step.user = current_user
      @step.last_modified_by = current_user
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


      # link tiny_mce_assets to the step
      TinyMceAsset.update_images(@step, params[:tiny_mce_images], current_user)

      @step.save!

      # Post process all assets
      @step.assets.each do |asset|
        asset.post_process_file(@protocol.team)
      end

      # link tiny_mce_assets to the step
      TinyMceAsset.update_images(@step, params[:tiny_mce_images], current_user)

      create_annotation_notifications(@step)

      # Generate activity
      if @protocol.in_module?
        log_activity(:create_step, @my_module.experiment.project, my_module: @my_module.id)
      else
        log_activity(:add_step_to_protocol_repository, nil, protocol: @protocol.id)
      end

      # Update protocol timestamp
      update_protocol_ts(@step)
    end

    respond_to do |format|
      if @step.errors.empty?
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

      # Attach newly uploaded files, and than remove their blob ids from the parameters
      new_assets = []
      step_params_all[:assets_attributes]&.each do |key, value|
        next unless value[:signed_blob_id]

        new_asset = @step.assets.create!(created_by: current_user, last_modified_by: current_user, team: current_team)
        new_asset.file
                 .attach(value[:signed_blob_id])
        new_assets.push(new_asset.id)
        step_params_all[:assets_attributes].delete(key)
      end

      @step.assign_attributes(step_params_all)
      @step.last_modified_by = current_user

      @step.tables.each do |table|
        table.created_by = current_user if table.new_record?
        table.last_modified_by = current_user unless table.new_record?
        table.team = current_team
      end
      if @step.save

        TinyMceAsset.update_images(@step, params[:tiny_mce_images], current_user)
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
          asset.post_process_file(team) if new_assets.include? asset.id
        end

        # Generate activity
        if @protocol.in_module?
          log_activity(:edit_step, @my_module.experiment.project, my_module: @my_module.id)
        else
          log_activity(:edit_step_in_protocol_repository, nil, protocol: @protocol.id)
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

  def update_view_state
    view_state = @step.current_view_state(current_user)
    view_state.state['assets']['sort'] = params.require(:assets).require(:order)
    view_state.save! if view_state.changed?
    respond_to do |format|
      format.json do
        render json: {}, status: :ok
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

      # Generate activity
      if @protocol.in_module?
        log_activity(:destroy_step, @my_module.experiment.project, my_module: @my_module.id)
      else
        log_activity(:delete_step_in_protocol_repository, nil, protocol: @protocol.id)
      end

      # Destroy the step
      @step.destroy(current_user)

      # Release space taken by the step
      team.release_space(previous_size)
      team.save

      # Update protocol timestamp
      update_protocol_ts(@step)

      flash[:success] = t(
        'protocols.steps.destroy.success_flash',
        step: (@step.position_plus_one).to_s
      )
    else
      flash[:error] = t(
        'protocols.steps.destroy.error_flash',
        step: (@step.position_plus_one).to_s
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
          completed_items = @chk_item.checklist.checklist_items
                                     .where(checked: true).count
          all_items = @chk_item.checklist.checklist_items.count
          text_activity = smart_annotation_parser(@chk_item.text)
                          .gsub(/\s+/, ' ')
          type_of = if checked
                      :check_step_checklist_item
                    else
                      :uncheck_step_checklist_item
                    end
          # This should always hold true (only in module can
          # check items be checked, but still check just in case)
          if @protocol.in_module?
            log_activity(type_of,
                         @protocol.my_module.experiment.project,
                         my_module: @my_module.id,
                         step: @chk_item.checklist.step.id,
                         step_position: { id: @chk_item.checklist.step.id,
                                          value_for: 'position_plus_one' },
                         checkbox: text_activity,
                         num_completed: completed_items.to_s,
                         num_all: all_items.to_s)
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

          type_of = completed ? :complete_step : :uncomplete_step
          # Toggling step state can only occur in
          # module protocols, so my_module is always
          # not nil; nonetheless, check if my_module is present
          if @protocol.in_module?
            log_activity(type_of,
                         @protocol.my_module.experiment.project,
                         my_module: @my_module.id,
                         num_completed: completed_steps.to_s,
                         num_all: all_steps.to_s)
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
    @step.update(update_params) unless update_params.empty?
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
  def has_destroy_params?(params)
    params.each do |key, values|
      next unless values.respond_to?(:each)

      params[key].each do |_, attrs|
        return true if attrs[:_destroy] == '1'
      end
    end

    false
  end

  # Extracts part of hash that contains destroy parameters. It deletes
  # values that contains destroy parameters from original variable and
  # puts them into update_params variable.
  def extract_destroy_params(params, update_params)
    params.each do |key, values|
      next unless values.respond_to?(:each)

      update_params[key] = {} unless update_params[key]
      attr_params = update_params[key]

      params[key].each do |pos, attrs|
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
        elsif has_destroy_params?(params[key][pos])
          attr_params[pos] = { id: attrs[:id] }
          extract_destroy_params(params[key][pos], attr_params[pos])
        end
      end
    end
  end

  def load_vars
    @step = Step.find_by_id(params[:id])
    @protocol = @step&.protocol
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
        :_destroy,
        :signed_blob_id
      ],
      tables_attributes: [
        :id,
        :name,
        :contents,
        :_destroy
      ],
      marvin_js_assets_attributes: %i(
        id
        _destroy
      )
    )
  end

  def log_activity(type_of, project = nil, message_items = {})
    default_items = { step: @step.id,
                      step_position: { id: @step.id, value_for: 'position_plus_one' } }
    message_items = default_items.merge(message_items)

    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            subject: @protocol,
            team: current_team,
            project: project,
            message_items: message_items)
  end
end
