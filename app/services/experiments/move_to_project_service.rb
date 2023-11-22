# frozen_string_literal: true

module Experiments
  class MoveToProjectService
    extend Service
    include Canaid::Helpers::PermissionsHelper

    attr_reader :errors

    def initialize(experiment_id:, project_id:, user_id:)
      @exp = Experiment.find_by(id: experiment_id)
      @project = Project.find_by(id: project_id)
      @user = User.find_by(id: user_id)
      @original_project = @exp&.project
      @errors = {}
    end

    def call
      return self unless valid?

      unless can_create_project_experiments?(@user, @project)
        @errors[:main] = I18n.t('move_to_project_service.project_permission_error')
        return self
      end

      ActiveRecord::Base.transaction do
        @exp.project = @project
        sync_user_assignments(@exp)

        @exp.my_modules.each do |my_module|
          unless can_move_my_module?(@user, my_module)
            @errors[:main] = I18n.t('move_to_project_service.my_modules_permission_error')
            raise
          end
          sync_user_assignments(my_module)
          clean_up_user_my_modules(my_module)
          move_tags!(my_module)
        end

        move_activities!(@exp)
        @exp.save!
      rescue StandardError
        if @exp.valid? && @errors.none?
          @errors[:main] = I18n.t('move_to_project_service.general_error')
        else
          @errors.merge!(@exp.errors.to_hash)
        end
        raise ActiveRecord::Rollback
      end

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

      if @exp.movable_projects(@user).include?(@project)
        true
      else
        @errors[:target_project_not_valid] =
          ['Experiment cannot be moved to this project']
      end
    end

    def move_tags!(my_module)
      new_tags = []
      my_module.tags.each do |tag|
        new_tag = @project.tags.where.not(id: new_tags).find_by(name: tag.name, color: tag.color)
        new_tag ||=
          @project.tags.create!(name: tag.name, color: tag.color, created_by: @user, last_modified_by: @user)
        new_tags << new_tag
      end
      my_module.tags.destroy_all
      my_module.tags = new_tags
    end

    # recursively move all activities in child associations to new project
    def move_activities!(subject)
      Activity.where(subject: subject).find_each do |activity|
        activity.update!(project: @project)
      end

      child_associations = Extends::ACTIVITY_SUBJECT_CHILDREN[subject.class.name.underscore.to_sym]
      return unless child_associations

      child_associations.each do |child_association|
        [subject.public_send(child_association)].flatten.each do |child_subject|
          next unless child_subject
          move_activities!(child_subject)
        end
      end
    end

    def sync_user_assignments(object)
      # remove user assignments where the user are not present on the project
      object.user_assignments.destroy_all

      UserAssignment.create!(
        user: @user,
        assignable: object,
        assigned: :automatically,
        user_role: @project.user_assignments.find_by(user: @user).user_role
      )

      UserAssignments::GenerateUserAssignmentsJob.perform_later(object, @user.id)
    end

    def clean_up_user_my_modules(my_module)
      my_module.user_my_modules.where.not(user_id: @project.users.select(:id)).destroy_all
    end

    def track_activity
      Activities::CreateActivityService
        .call(activity_type: :move_experiment,
              owner: @user,
              team: @project.team,
              project: @project,
              subject: @exp,
              message_items: { experiment: @exp.id,
                               project_new: @project.id,
                               project_original: @original_project.id })
    end
  end
end
