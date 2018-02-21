class CanvasController < ApplicationController
  before_action :load_vars

  before_action :check_view_canvas, only: [:edit, :full_zoom, :medium_zoom, :small_zoom]
  before_action :check_edit_canvas, only: [:edit, :update]

  def edit
    render partial: 'canvas/edit',
      locals: { experiment: @experiment, my_modules: @my_modules },
      :content_type => 'text/html'
  end

  def full_zoom
    render partial: 'canvas/full_zoom',
      locals: { experiment: @experiment, my_modules: @my_modules },
      :content_type => 'text/html'
  end

  def medium_zoom
    render partial: 'canvas/medium_zoom',
      locals: { experiment: @experiment, my_modules: @my_modules },
      :content_type => 'text/html'
  end

  def small_zoom
    render partial: 'canvas/small_zoom',
      locals: { experiment: @experiment, my_modules: @my_modules },
      :content_type => 'text/html'
  end

  def update
    # Make sure that remove parameter is valid
    to_archive = []
    if update_params[:remove].present?
      to_archive = update_params[:remove].split(',')
      if to_archive.all? do |id|
           is_int?(id) &&
           can_manage_module?(MyModule.find_by_id(id))
         end
        to_archive.collect!(&:to_i)
      else
        return render_403
      end
    end

    # Make sure connections parameter is valid
    connections = []
    if update_params[:connections].present?
      conns = update_params[:connections].split(',')
      if conns.length.even? && conns.all? { |c| c.is_a? String }
        conns.each_slice(2).each do |c|
          connections << [c[0], c[1]]
        end
      else
        return render_403
      end
    end

    # Make sure positions parameter is valid
    positions = {}
    if update_params[:positions].present?
      poss = update_params[:positions].split(';')
      center = ''
      (poss.collect { |pos| pos.split(',') }).each_with_index do |pos, index|
        unless pos.length == 3 && pos[0].is_a?(String) &&
               float?(pos[1]) && float?(pos[2])
          return render_403
        end
        if index.zero?
          center = pos
          x = 0
          y = 0
        else
          x = pos[1].to_i - center[1].to_i
          y = pos[2].to_i - center[2].to_i
        end
        # Multiple modules cannot have same position
        return render_403 if positions.any? { |_, v| v[:x] == x && v[:y] == y }
        positions[pos[0]] = { x: x, y: y }
      end
    end

    # Make sure that to_add is an array of strings,
    # as well as that positions for newly added modules exist
    to_add = []
    if update_params[:add].present? &&
       update_params['add-names'].present?
      ids = update_params[:add].split(',')
      names = update_params['add-names'].split('|')
      if ids.length == names.length &&
         ids.all? { |id| id.is_a?(String) && positions.include?(id) } &&
         names.all? { |name| name.is_a? String }
        ids.each_with_index do |id, i|
          to_add << { id: id, name: names[i],
                      x: positions[id][:x], y: positions[id][:y] }
        end
      else
        return render_403
      end
    end

    # Make sure rename parameter is valid
    to_rename = {}
    if update_params[:rename].present?
      begin
        to_rename = JSON.parse(update_params[:rename])
        # Okay, JSON parsed!
        unless to_rename.is_a?(Hash) &&
               to_rename.keys.all? do |id|
                 id.is_a?(String) &&
                 can_manage_module?(MyModule.find_by_id(id))
               end &&
               to_rename.values.all? { |new_name| new_name.is_a? String }
          return render_403
        end
      rescue
        return render_403
      end
    end

    # Make sure move parameter is valid
    to_move = {}
    if update_params[:move].present?
      begin
        to_move = JSON.parse(update_params[:move])
        # Okay, JSON parsed!
        unless to_move.is_a?(Hash) &&
               to_move.keys.all? do |id|
                 id.is_a?(String) &&
                 (!is_int?(id) || can_manage_module?(MyModule.find_by_id(id)))
               end &&
               to_move.values.all? do |exp_id|
                 exp_id.is_a?(String) &&
                 can_manage_experiment?(Experiment.find_by_id(exp_id))
               end
          return render_403
        end
      rescue
        return render_403
      end
    end

    # Distinguish between moving modules/module_groups
    to_move_groups = {}
    to_move.each do |key, value|
      if key =~ /.*,.*/
        to_move_groups[key.split(',')] = value
        to_move.delete(key)
      end
    end

    # Make sure that to_clone is an array of pairs,
    # as well as that all IDs exist
    to_clone = {}
    if update_params[:cloned].present?
      clones = update_params[:cloned].split(';')
      (clones.collect { |v| v.split(',') }).each do |val|
        if val.length == 2 && is_int?(val[0]) && val[1].is_a?(String) &&
           to_add.any? { |m| m[:id] == val[1] }
          to_clone[val[1]] = val[0]
        else
          return render_403
        end
      end
    end

    # Call the "master" function to do all the updating for us
    unless @experiment.update_canvas(
      to_archive,
      to_add,
      to_rename,
      to_move,
      to_move_groups,
      to_clone,
      connections,
      positions,
      current_user
    )
      return render_403
    end

    # Save activities that modules were archived
    to_archive.each do |module_id|
      my_module = MyModule.find_by_id(module_id)
      next if my_module.blank?
      Activity.create(type_of: :archive_module,
        project: my_module.experiment.project,
        experiment: my_module.experiment,
        my_module: my_module,
        user: current_user,
        message: t('activities.archive_module',
                   user: current_user.full_name,
                   module: my_module.name))
    end

    # Create workflow image
    @experiment.delay.generate_workflow_img

    flash[:success] = t('experiments.canvas.update.success_flash')
    redirect_to canvas_experiment_path(@experiment)
  end

  private

  def update_params
    params.permit(
      :id,
      :connections,
      :positions,
      :add,
      "add-names",
      :rename,
      :move,
      :cloned,
      :remove,
      "module-groups"
    )
  end

  def load_vars
    @experiment = Experiment.find_by_id(params[:id])
    unless @experiment
      respond_to do |format|
        format.html { render_404 and return }
        format.any(:xml, :json, :js) { render(json: { redirect_url: not_found_url }, status: :not_found) and return }
      end
    end

    @my_modules = @experiment.active_modules
  end

  def check_edit_canvas
    render_403 and return unless can_manage_experiment?(@experiment)
  end

  def check_view_canvas
    render_403 unless can_read_experiment?(@experiment)
  end

  # Check if given value is "integer" string (e.g. "15")
  def is_int?(val)
    /\A[-+]?\d+\z/ === val
  end

  def float?(val)
    true if Float(val)
  rescue ArgumentError
    false
  end
end
