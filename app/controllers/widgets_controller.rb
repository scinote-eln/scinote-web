class WidgetsController < ApplicationController
  before_action :load_vars, only: [:destroy, :move_up, :move_down]
  before_action :check_destroy_permissions, only: [:destroy]

  def destroy
    # Update position on other widgets of this module
    @my_module.widgets.where('position > ?', @widget.position).each do |widget|
      widget.position = widget.position - 1
      widget.save
    end

    @widget.destroy
    update_my_module_ts(@widget)

    flash[:success] = t('my_modules.overview.widgets.destroy.success_flash',
                        type: @widget.widget_type.capitalize,
                        pos: @widget.position + 1)
    redirect_to overview_my_module_path(@my_module)
  end

  def move_up
    respond_to do |format|
      if @widget
        if can_reorder_widget_in_my_module(@widget.my_module) &&
           @widget.position > 0

          widget_down = @widget.my_module.widgets
                               .where(position: @widget.position - 1).first

          if widget_down
            # Needed to bypass uniqueness constraint when switching values
            widget_down.position = Constants::INFINITY
            widget_down.save

            widget_down.position = @widget.position
            @widget.position -= 1
            @widget.save
            widget_down.save

            update_my_module_ts(@widget)

            format.json do
              render json: { move_direction: 'up',
                             widget_up_position: @widget.position,
                             widget_down_position: widget_down.position },
              status: :ok
            end
          else
            format.json do
              render json: {}, status: :forbidden
            end
          end
        else
          format.json do
            render json: {}, status: :forbidden
          end
        end
      else
        format.json do
          render json: {}, status: :not_found
        end
      end
    end
  end

  def move_down
    respond_to do |format|
      if @widget
        if can_reorder_widget_in_my_module(@widget.my_module) &&
           @widget.position < @widget.my_module.widgets.count - 1

          widget_up = @widget.my_module.widgets
                             .where(position: @widget.position + 1).first

          if widget_up
            # Needed to bypass uniqueness constraint when switching values
            widget_up.position = Constants::INFINITY
            widget_up.save

            widget_up.position = @widget.position
            @widget.position += 1
            @widget.save
            widget_up.save

            update_my_module_ts(@widget)

            format.json do
              render json: { move_direction: 'down',
                             widget_up_position: widget_up.position,
                             widget_down_position: @widget.position },
              status: :ok
            end
          else
            format.json do
              render json: {}, status: :forbidden
            end
          end
        else
          format.json do
            render json: {}, status: :forbidden
          end
        end
      else
        format.json do
          render json: {}, status: :not_found
        end
      end
    end
  end

  private

  def load_vars
    @widget = Widget.find_by_id(params[:id])
    @my_module = @widget.my_module
    render_404 unless @my_module
  end

  def update_my_module_ts(widget)
    if widget.present? && widget.my_module.present?
      widget.my_module.update(updated_at: Time.now)
    end
  end

  def check_destroy_permissions
    render_403 unless can_delete_widget_in_my_module(@my_module)
  end
end
