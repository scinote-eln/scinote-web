# frozen_string_literal: true

class UserMyModulesController < ApplicationController
  include InputSanitizeHelper

  before_action :load_vars
  before_action :check_view_permissions, except: %i(create destroy)
  before_action :check_manage_permissions, only: %i(create destroy)

  def designated_users
    @user_my_modules = @my_module.user_my_modules

    render json: {
      html: render_to_string(partial: 'designated_users', formats: :html),
      my_module_id: @my_module.id,
      counter: @my_module.designated_users.count # Used for counter badge
    }
  end

  def index
    render json: {
      html: render_to_string(partial: 'index', formats: :html)
    }
  end

  def index_edit
    @user_my_modules = @my_module.user_my_modules
    @undesignated_users = @my_module.undesignated_users.order(full_name: :asc)
    @new_um = UserMyModule.new(my_module: @my_module)

    render json: {
      my_module: @my_module,
      html: render_to_string(
        partial: 'index_edit', formats: :html
      )
    }
  end

  def create
    @um = UserMyModule.new(um_params.merge(my_module: @my_module))
    @um.assigned_by = current_user

    if @um.save
      @um.log_activity(:designate_user_to_my_module, current_user)

      if params[:table]
        render json: {
          html: render_to_string(partial: 'experiments/assigned_users',
                                 locals: { my_module: @my_module, user: current_user, skip_unassigned: false },
                                 formats: :html),
          unassign_url: my_module_user_my_module_path(@my_module, @um)
        }
      else
        render json: {
          user: {
            id: @um.user.id,
            full_name: escape_input(@um.user.full_name),
            avatar_url: avatar_path(@um.user, :icon_small),
            user_module_id: @um.id
          }
        }
      end
    else
      render json: {
        errors: @um.errors
      }, status: :unprocessable_entity
    end
  end

  def destroy
    if @um.destroy
      @um.log_activity(:undesignate_user_from_my_module, current_user)

      if params[:table]
        render json: {
          html: render_to_string(partial: 'experiments/assigned_users',
                                 locals: { my_module: @my_module, user: current_user, skip_unassigned: false },
                                 formats: :html)
        }
      else
        render json: {}
      end
    else
      render json: {
        errors: @um.errors
      }, status: :unprocessable_entity
    end
  end

  def search
    users = @my_module.users
                      .joins("LEFT OUTER JOIN user_my_modules ON user_my_modules.user_id = users.id "\
                             "AND user_my_modules.my_module_id = #{@my_module.id}")
                      .search(false, params[:query])
                      .select('users.*', 'user_my_modules.id as user_my_module_id')
                      .select('CASE WHEN user_my_modules.id IS NOT NULL THEN true ELSE false END as designated')
                      .order('designated DESC', :full_name)

    users = users.map do |user|
      next if params[:skip_assigned] && user.designated
      next if ActiveModel::Type::Boolean.new.cast(params[:skip_unassigned]) && !user.designated

      user_hash = {
        value: user.id,
        label: escape_input(user.full_name),
        params: {
          avatar_url: avatar_path(user, :icon_small),
          designated: user.designated,
          assign_url: my_module_user_my_modules_path(@my_module)
        }
      }

      if user.designated
        user_hash[:params][:unassign_url] = my_module_user_my_module_path(@my_module, user.user_my_module_id)
      end

      user_hash
    end

    render json: {
      users: users.compact
    }
  end

  private

  def load_vars
    @my_module = MyModule.find(params[:my_module_id])
    @project = @my_module.experiment.project
    @um = UserMyModule.find(params[:id]) if action_name == 'destroy'
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def check_view_permissions
    render_403 unless can_read_my_module?(@my_module)
  end

  def check_manage_permissions
    render_403 unless can_manage_my_module_designated_users?(@my_module)
  end

  def um_params
    params.require(:user_my_module).permit(:user_id, :my_module_id)
  end
end
