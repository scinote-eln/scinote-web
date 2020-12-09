# frozen_string_literal: true

class CreateMyModuleService
<<<<<<< HEAD
  include Canaid::Helpers::PermissionsHelper

=======
>>>>>>> Pulled latest release
  def initialize(user, team, params)
    @params = params
    @my_module_params = params[:my_module] || {}
    @user = user
    @team = team
  end

  def call
<<<<<<< HEAD
    ActiveRecord::Base.transaction do
      unless @params[:experiment].instance_of?(Experiment)
        @params[:experiment][:project] = @params[:project]
        @params[:experiment] = CreateExperimentService.new(@user, @team, @params[:experiment]).call
      end

      raise ActiveRecord::Rollback unless @params[:experiment]&.valid? &&
                                          can_manage_experiment_tasks?(@user, @params[:experiment])
=======
    new_my_module = nil
    ActiveRecord::Base.transaction do
      unless @params[:experiment].class == Experiment
        @params[:experiment][:project] = @params[:project]
        @params[:experiment] = CreateExperimentService.new(@user, @team, @params[:experiment]).call
      end
      unless @params[:experiment]&.errors&.empty?
        new_my_module = @params[:experiment]
        raise ActiveRecord::Rollback
      end
>>>>>>> Pulled latest release

      @my_module_params[:x] ||= 0
      @my_module_params[:y] ||= 0
      @my_module_params[:name] ||= I18n.t('create_task_service.default_task_name')

      @my_module = @params[:experiment].my_modules.new(@my_module_params)

      new_pos = @my_module.get_new_position
      @my_module.x = new_pos[:x]
      @my_module.y = new_pos[:y]
      @my_module.created_by = @user
      @my_module.last_modified_by = @user

      @my_module.save!
      create_my_module_activity

      @my_module.assign_user(@user)
<<<<<<< HEAD
    end

    @my_module
=======

      new_my_module = @my_module
    end
    new_my_module
>>>>>>> Pulled latest release
  end

  private

  def create_my_module_activity
    Activities::CreateActivityService
      .call(activity_type: :create_module,
            owner: @user,
            team: @team,
            project: @params[:experiment].project,
            subject: @my_module,
            message_items: { my_module: @my_module.id })
  end
end
