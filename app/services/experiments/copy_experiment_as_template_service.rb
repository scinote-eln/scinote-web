# frozen_string_literal: true

module Experiments
  class CopyExperimentAsTemplateService
    extend Service

    attr_reader :errors, :c_exp
    alias cloned_experiment c_exp

    def initialize(experiment:, project:, user:)
      @exp = experiment
      @project = project
      @user = user
      @original_project = @exp.project
      @c_exp = nil
      @errors = {}
    end

    def call
      return self unless valid?

      ActiveRecord::Base.transaction do
        @c_exp = Experiment.new(
          name: @exp.next_clone_name,
          description: @exp.description,
          created_by: @user,
          last_modified_by: @user,
          project: @project
        )

        # Copy all signle taskas
        @c_exp.my_modules << @exp.my_modules.readable_by_user(@user).without_group.map do |m|
          m.deep_clone_to_experiment(@user, @c_exp)
        end

        # Copy all grouped tasks
        @exp.my_module_groups.each do |g|
          @c_exp.my_module_groups << g.deep_clone_to_experiment(@user, @c_exp)
        end

        @c_exp.save!
      end
      @errors.merge!(@c_exp.errors.to_hash) unless @c_exp.valid?

      @c_exp = nil unless succeed?
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
          { experiment: @exp,
            project: @project,
            user: @user }
          .map do |key, value|
            "Can't find #{key.capitalize}" if value.nil?
          end.compact
        false
      end

      true
    end

    def track_activity
      Activities::CreateActivityService
        .call(activity_type: :clone_experiment,
              owner: @user,
              team: @project.team,
              project: @c_exp.project,
              subject: @c_exp,
              message_items: { experiment_new: @c_exp.id,
                               experiment_original: @exp.id })
    end
  end
end
