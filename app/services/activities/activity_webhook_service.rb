# frozen_string_literal: true

module Activities
  class ActivityWebhookService
    def initialize(webhook, activity)
      @webhook = webhook
      @activity = activity
    end

    def send_webhook
      WebhookService.new(@webhook, activity_payload).send_webhook
    end

    def activity_payload
      @activity.values.merge(
        type: @activity.type_of,
        created_at: @activity.created_at,
        subject: {
          type: @activity.subject_type,
          id: @activity.subject_id
        },
        subject_breadcrumbs: @activity.subject_parents.map do |subject|
          { type: subject.model_name.human.downcase, id: subject.id }
        end
      )
    end
  end
end
