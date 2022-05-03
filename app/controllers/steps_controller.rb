class StepsController < ApplicationController
  include ActionView::Helpers::TextHelper
  include ApplicationHelper
  include StepsActions
  include MarvinJsActions

  before_action :load_vars, only: %i(edit update destroy show toggle_step_state checklistitem_state update_view_state
                                     move_up move_down update_asset_view_mode elements)
  before_action :load_vars_nested, only:  %i(new create index)
  before_action :convert_table_contents_to_utf8, only: %i(create update)

  before_action :check_view_permissions, only: %i(show index)
  before_action :check_create_permissions, only: %i(new create)
  before_action :check_manage_permissions, only: %i(edit update destroy move_up move_down
                                                    update_view_state update_asset_view_mode)
  before_action :check_complete_and_checkbox_permissions, only: %i(toggle_step_state checklistitem_state)

  def index
    render json: @protocol.steps.in_order, each_serializer: StepSerializer
  end

  def elements
    render json: @step.step_orderable_elements.order(:position), each_serializer: StepOrderableElementSerializer
  end

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
    @step = Step.new(
      name: t('protocols.steps.default_name'),
      completed: false,
      user: current_user,
      last_modified_by: current_user
    )

    @step = @protocol.insert_step(@step, params[:position])
    # Generate activity
    if @protocol.in_module?
      log_activity(:create_step, @my_module.experiment.project, my_module: @my_module.id)
    else
      log_activity(:add_step_to_protocol_repository, nil, protocol: @protocol.id)
    end
    render json: @step, serializer: StepSerializer
  end

  def create_old
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
    end

    respond_to do |format|
      if @step.errors.blank?
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
    if @step.update(step_params)
      # Generate activity
      if @protocol.in_module?
        log_activity(:edit_step, @my_module.experiment.project, my_module: @my_module.id)
      else
        log_activity(:edit_step_in_protocol_repository, nil, protocol: @protocol.id)
      end
      render json: @step, serializer: StepSerializer
    else
      render json: {}, status: :unprocessable_entity
    end
  end

  def update_old
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

        new_asset = @step.assets.create!(
          created_by: current_user,
          last_modified_by: current_user,
          team: current_team,
          view_mode: @step.assets_view_mode
        )
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

      update_checklist_items_without_callback(step_params_all)

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

  def update_asset_view_mode
    html = ''
    ActiveRecord::Base.transaction do
      @step.assets_view_mode = params[:assets_view_mode]
      @step.save!(touch: false)
      @step.assets.update_all(view_mode: @step.assets_view_mode)
    end
    @step.assets.each do |asset|
      html += render_to_string(partial: 'assets/asset.html.erb', locals: {
                                 asset: asset,
                                 gallery_view_id: @step.id
                               })
    end
    render json: { html: html }, status: :ok
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error(e.message)
    render json: { errors: e.message }, status: :unprocessable_entity
  end

  def destroy
    if @step.can_destroy?

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
      @step.destroy

      # Release space taken by the step
      team.release_space(previous_size)
      team.save
    end

    render json: @step, serializer: StepSerializer
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
    @step.completed = params[:completed] == 'true'
    @step.last_modified_by = current_user

    if @step.save
      # Create activity
      if @step.saved_change_to_completed
        completed_steps = @protocol.steps.where(completed: true).count
        all_steps = @protocol.steps.count

        type_of = @step.completed ? :complete_step : :uncomplete_step
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
      render json: @step, serializer: StepSerializer
    else
      render json: {}, status: :unprocessable_entity
    end
  end

  def move_up
    respond_to do |format|
      format.json do
        @step.move_up

        render json: {
          steps_order: @protocol.steps.order(:position).select(:id, :position)
        }
      end
    end
  end

  def move_down
    respond_to do |format|
      format.json do
        @step.move_down

        render json: {
          steps_order: @protocol.steps.order(:position).select(:id, :position)
        }
      end
    end
  end

  private

  # This function is used for partial update of step references and
  # it's useful when you want to execute destroy action on attribute
  # collection separately from normal update action, for example if
  # you don't want that update validation interupt destroy action.
  # In case of step model you can delete checkboxes, assets or tables.
  def destroy_attributes(params)
    update_params = {}
    delete_step_tables(params)
    extract_destroy_params(params, update_params)
    @step.update(update_params) unless update_params.blank?
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
    @step = Step.find_by(id: params[:id])
    return render_404 unless @step

    @protocol = @step.protocol
    @chk_item = ChecklistItem.find_by(id: params[:checklistitem_id]) if params[:checklistitem_id]
    @my_module = @protocol.my_module if @protocol.in_module?
  end

  def load_vars_nested
    @protocol = Protocol.find_by(id: params[:protocol_id])

    return render_404 unless @protocol

    @my_module = @protocol.my_module if @protocol.in_module?
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

  def update_checklist_items_without_callback(params)
    params.dig('checklists_attributes')&.values&.each do |cl|
      ck = @step.checklists.find_by(id: cl[:id])
      next if ck.nil? # ck is new checklist, skip update positions

      cl['checklist_items_attributes']&.each do |item|
        # Here item is somehow array of index and parameters [0, paramteters<Object>], should be fixed on FE also
        item_record = ck.checklist_items.find_by(id: item[1][:id])

        next unless item_record

        item_record.update_attribute('position', item[1][:position])
      end
    end
  end

  def check_view_permissions
    render_403 unless can_read_protocol_in_module?(@protocol) || can_read_protocol_in_repository?(@protocol)
  end

  def check_manage_permissions
    render_403 unless can_manage_step?(@step)
  end

  def check_create_permissions
    if @my_module
      render_403 unless can_manage_my_module_steps?(@my_module)
    else
      render_403 unless can_manage_protocol_in_repository?(@protocol)
    end
  end

  def check_complete_and_checkbox_permissions
    render_403 unless can_complete_or_checkbox_step?(@protocol)
  end

  def step_params
    params.require(:step).permit(:name)
  end

  def step_params_old
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
      ),
       bio_eddie_assets_attributes: %i(
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
