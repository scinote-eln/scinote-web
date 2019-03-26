# frozen_string_literal: true

module Activities
  class CreateActivityService
    extend Service

    attr_reader :errors, :activity

    def initialize(activity_type:,
                   owner:,
                   team:,
                   project: nil,
                   subject:,
                   message_items: {})
      @activity = Activity.new
      @activity.type_of = activity_type
      @activity.owner = owner
      @activity.team = team
      @activity.subject = subject
      @activity.project = project if project
      @message_items = message_items

      @errors = {}
    end

    def call
      enrich_message_items
      @activity.save!
      @activity.generate_breadcrumbs
      self
    end

    def succeed?
      @errors.none?
    end

    private

    def enrich_message_items
      @message_items.each do |k, v|
        const = try_to_constantize k
        if const
          if v.is_a?(Hash) # Value is array, so you have getter specified
            id = v[:id]
            getter_method = v[:value_for]
          else
            id = v
            getter_method = 'name'
          end

          obj = const.find id
          @activity.message_items[k] = {
            type: const.to_s,
            value: obj.public_send(getter_method).to_s,
            id: id
          }

          @activity.message_items[k].merge!(value_for: getter_method)

        else
          @activity.message_items[k] = v.to_s
        end
      end
    end

    def try_to_constantize(key)
      const_name = key.to_s.camelize
      # Remove last part from and with '_xxx..x'
      const_name_short = key.to_s.sub(/_[^_]*\z/, '').camelize

      if Extends::ACTIVITY_MESSAGE_ITEMS_TYPES.include? const_name
        const_name.constantize
      elsif Extends::ACTIVITY_MESSAGE_ITEMS_TYPES.include? const_name_short
        const_name_short.constantize
      else
        false
      end
    end
  end
end
