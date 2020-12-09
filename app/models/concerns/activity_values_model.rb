# frozen_string_literal: true

module ActivityValuesModel
  extend ActiveSupport::Concern

  # rubocop:disable Style/ClassVars
  @@default_values = HashWithIndifferentAccess.new
  # rubocop:enable Style/ClassVars

  included do
    after_initialize :init_default_values, if: :new_record?
    before_create :add_user
  end

  class_methods do
    def default_values(dfs)
      @@default_values.merge!(dfs)
    end
  end

  protected

  def init_default_values
    self.values = @@default_values
  end

  def add_user
    message_items.merge!(user: { id: owner.id,
                                 value: owner.full_name,
                                 type: 'User',
                                 value_for: 'full_name' })
  end
end
