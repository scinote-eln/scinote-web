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
        subject: serialized_subject,
        subject_breadcrumbs: @activity.subject_parents.map do |subject|
          { type: subject.model_name.human.downcase, id: subject.id }
        end
      )
    end

    private

    def serialized_subject
      return { type: @activity.subject_type, id: @activity.subject_id } unless @webhook.include_serialized_subject

      serializer_name = Extends::ACTIVITY_SUBJECT_TYPE_API_SERIALIZER_MAP[@activity.subject_type]

      unless serializer_name
        return {
          type: @activity.subject_type,
          id: @activity.subject_id,
          error: I18n.t('api.webhooks.errors.subject_not_serializable')
        }
      end

      serializer_name.constantize.new(@activity.subject).as_json
    end
  end
end
