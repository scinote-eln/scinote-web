# frozen_string_literal: true

class CreateMyModuleService
  include Canaid::Helpers::PermissionsHelper
  attr_reader :errors

  def initialize(user, team, params)
    @params = params
    @my_module_params = params[:my_module] || {}
    @user = user
    @team = team
    @errors = {}
  end

  def call
    ActiveRecord::Base.transaction do
      unless @params[:experiment].instance_of?(Experiment)
        @params[:experiment][:project] = @params[:project]
        experiment_service = CreateExperimentService.new(@user, @team, @params[:experiment])
        @params[:experiment] = experiment_service.call
        @errors.merge!(experiment_service.errors) if experiment_service&.errors&.any?
      end

      raise ActiveRecord::Rollback unless @params[:experiment]&.valid? &&
                                          can_create_experiment_tasks?(@user, @params[:experiment])

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
    end
    @my_module
  rescue ActiveRecord::RecordInvalid
    @errors['my_module'] = @my_module.errors.messages if @my_module
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
