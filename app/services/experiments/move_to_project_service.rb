# frozen_string_literal: true

module Experiments
  class MoveToProjectService
    extend Service

    attr_reader :errors

    def initialize(experiment_id:, project_id:, user_id:)
      @exp = Experiment.find experiment_id
      @project = Project.find project_id
      @user = User.find user_id
      @original_project = @exp&.project
      @errors = {}
    end

    def call
      return self unless valid?

      ActiveRecord::Base.transaction do
        @exp.project = @project

        @exp.my_modules.each do |m|
          new_tags = m.tags.map do |t|
            t.clone_to_project_or_return_existing(@project)
          end
          m.my_module_tags.delete_all
          m.tags = new_tags
        end

        raise ActiveRecord::Rollback unless @exp.save
        # To pass the ExperimentsController#updated_img check
        @exp.update(workflowimg_updated_at: @exp.updated_at)
      end

      @errors.merge!(@exp.errors.to_hash) unless @exp.valid?

      track_activity if succeed?
      self
    end

    def succeed?
      @errors.none?
    end

    private

    def valid?
      unless @exp && @project && @user
        @errors[:invalid_arguments] =
          { 'experiment': @exp,
            'project': @project,
            'user': @user }
          .map do |key, value|
            "Can't find #{key.capitalize}" if value.nil?
          end.compact
        return false
      end

      e = Experiment.find_by(name: @exp.name, project: @project)

      if e
        @errors[:project_with_exp] =
          ['Project already contains experiment with this name']
        false
      elsif !@exp.moveable_projects(@user).include?(@project)
        @errors[:target_project_not_valid] =
          ['Experiment cannot be moved to this project']
        false
      else
        true
      end
    end

    def track_activity
      Activity.create(
        type_of: :move_experiment,
        project: @project,
        subject: @exp,
        owner: @user,
        message: I18n.t(
          'activities.move_experiment',
          user: @user,
          experiment: @exp.name,
          project_new: @project.name,
          project_original: @original_project.name
        )
      )
    end
  end
end
