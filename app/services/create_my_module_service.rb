# frozen_string_literal: true

class CreateMyModuleService
  def initialize(user, team, params)
    @params = params
    @my_module_params = params[:my_module] || {}
    @user = user
    @team = team
  end

  def call
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

      @my_module_params[:x] ||= 0
      @my_module_params[:y] ||= 0
      @my_module_params[:name] ||= I18n.t('create_task_service.default_task_name')

      @my_module = @params[:experiment].my_modules.new(@my_module_params)

      new_pos = @my_module.get_new_position
      @my_module.x = new_pos[:x]
      @my_module.y = new_pos[:y]

      @my_module.save!
      create_my_module_activity

      @my_module.assign_user(@user)

      @params[:experiment].generate_workflow_img
      new_my_module = @my_module
    end
    new_my_module
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
