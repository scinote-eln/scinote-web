# frozen_string_literal: true

module Notifications
  class PushToCommunicationChannelService
    extend Service

    WHITELISTED_ITEM_TYPES = %w(SystemNotification).freeze

    attr_reader :errors

    def initialize(item_id:, item_type:)
      @item_type = item_type
      @item = item_type.constantize.find item_id
      @errors = {}
    end

    def call
      return self unless valid?

      "Notifications::Handle#{@item_type}InCommunicationChannelService".constantize.call(@item)
      self
    end

    def succeed?
      @errors.none?
    end

    private

    def valid?
      raise 'Dont know how to handle this type of items' unless WHITELISTED_ITEM_TYPES.include?(@item_type)

      if @item.nil?
        @errors[:invalid_arguments] = 'Can\'t find item' if @item.nil?
        return false
      end
      true
    end
  end
end
