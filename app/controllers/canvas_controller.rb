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
    error = false

    # Make sure that remove parameter is valid
    to_archive = []
    if can_archive_modules(@experiment) and
      update_params[:remove].present? then
      to_archive = update_params[:remove].split(",")
      unless to_archive.all? { |id| is_int? id }
        error = true
      else
        to_archive.collect! { |id| id.to_i }
      end
    end

    if error then
      render_403 and return
    end

    # Make sure connections parameter is valid
    connections = []
    if can_edit_connections(@experiment) and
      update_params[:connections].present? then
      conns = update_params[:connections].split(",")
      unless conns.length % 2 == 0 and
        conns.all? { |c| c.is_a? String } then
        error = true
      else
        conns.each_slice(2).each do |c|
          connections << [c[0], c[1]]
        end
      end
    end

    if error then
      render_403 and return
    end

    # Make sure positions parameter is valid
    positions = Hash.new
    if can_reposition_modules(@experiment) and
      update_params[:positions].present? then
      poss = update_params[:positions].split(";")
      center = ""
      (poss.collect { |pos| pos.split(",") }).each_with_index do |pos, index|
        unless (pos.length == 3 and
          pos[0].is_a? String and
          is_int? pos[1] and
          is_int? pos[2])
          error = true
          break
        end
        if index == 0
          center = pos
          x = 0
          y = 0
        else
          x = pos[1].to_i - center[1].to_i
          y = pos[2].to_i - center[2].to_i
        end
        # Multiple modules cannot have same position
        if positions.any? { |k,v| v[:x] == x and v[:y] == y} then
          error = true
          break
        end
        positions[pos[0]] = { x: x, y: y }
      end
    end

    if error then
      render_403 and return
    end

    # Make sure that to_add is an array of strings,
    # as well as that positions for newly added modules exist
    to_add = []
    if can_create_modules(@experiment) and
      update_params[:add].present? and
      update_params["add-names"].present? then
      ids = update_params[:add].split(",")
      names = update_params["add-names"].split("|")
      unless ids.length == names.length and
        ids.all? { |id| id.is_a? String and positions.include? id } and
        names.all? { |name| name.is_a? String }
        error = true
      else
        ids.each_with_index do |id, i|
          to_add << {
            id: id,
            name: names[i],
            x: positions[id][:x],
            y: positions[id][:y]
          }
        end
      end
    end

    if error then
      render_403 and return
    end

    # Make sure rename parameter is valid
    to_rename = Hash.new
    if can_edit_modules(@experiment) and
      update_params[:rename].present? then
      begin
        to_rename = JSON.parse(update_params[:rename])

        # Okay, JSON parsed!
        unless (
          to_rename.is_a? Hash and
          to_rename.keys.all? { |k| k.is_a? String } and
          to_rename.values.all? { |k| k.is_a? String }
        )
          error = true
        end
      rescue
        error = true
      end
    end

    if error then
      render_403 and return
    end

    # Make sure that to_clone is an array of pairs,
    # as well as that all IDs exist
    to_clone = Hash.new
    if can_clone_modules(@experiment) and
      update_params[:cloned].present? then
      clones = update_params[:cloned].split(";")
      (clones.collect { |v| v.split(",") }).each do |val|
        unless (val.length == 2 and
          is_int? val[0] and
          val[1].is_a? String and
          to_add.any? { |m| m[:id] == val[1] })
          error = true
          break
        else
          to_clone[val[1]] = val[0]
        end
      end
    end

    if error then
      render_403 and return
    end

    module_groups = Hash.new
    if can_edit_module_groups(@experiment) and
      update_params["module-groups"].present? then
      begin
        module_groups = JSON.parse(update_params["module-groups"])

        # Okay, JSON parsed!
        unless (
          module_groups.is_a? Hash and
          module_groups.keys.all? { |k| k.is_a? String } and
          module_groups.values.all? { |k| k.is_a? String }
        )
          error = true
        end
      rescue
        error = true
      end
    end

    if error then
      render_403 and return
    end

    # Call the "master" function to do all the updating for us
    unless @experiment.update_canvas(
      to_archive,
      to_add,
      to_rename,
      to_clone,
      connections,
      positions,
      current_user,
      module_groups
    )
      render_403 and return
    end

    #Save activities that modules were archived
    to_archive.each do |module_id|
      my_module = MyModule.find_by_id(module_id)
      unless my_module.blank?
        Activity.create(
          type_of: :archive_module,
          project: my_module.experiment.project,
          my_module: my_module,
          user: current_user,
          message: t(
            'activities.archive_module',
            user: current_user.full_name,
            module: my_module.name
          )
        )
      end
    end

    # Create workflow image
    @experiment.delay.generate_workflow_img

    flash[:success] = t(
      "experiments.canvas.update.success_flash")
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
    unless can_edit_canvas(@experiment)
      render_403 and return
    end
  end

  def check_view_canvas
    unless can_view_experiment(@experiment)
      render_403 and return
    end
  end

  # Check if given value is "integer" string (e.g. "15")
  def is_int?(val)
    /\A[-+]?\d+\z/ === val
  end

end
