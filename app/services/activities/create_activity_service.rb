# frozen_string_literal: true

module Activities
  class CreateActivityService
    extend Service

    attr_reader :errors, :activity

    def initialize(activity_type:,
                   owner:,
                   team:,
                   project:,
                   subject:,
                   message_items: {})
      @activity = Activity.new
      @activity.type_of = activity_type
      @activity.owner = owner
      @activity.team = team
      @activity.subject = subject
      @activity.project = project if project
      @activity.values = { message_items: message_items }

      @errors = {}
    end

    def call
      generate_breadcrumbs
      @activity.save

      self
    end

    def succeed?
      @errors.none?
    end

    private

    def generate_breadcrumbs
      @activity.values[:breadcrumbs] = [
        { team: { id: @activity.team.id, value: @activity.team.name } },
        { project: { id: @activity.project.id, value: @activity.project.name } }
      ]
    end
  end
end
