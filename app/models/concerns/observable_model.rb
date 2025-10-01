# frozen_string_literal: true

module ObservableModel
  extend ActiveSupport::Concern

  included do
    after_create :notify_observers_on_create
    after_update :notify_observers_on_update
    after_destroy :notify_observers_on_destroy
  end

  private

  def changed_by
    last_modified_by || created_by
  end

  def notify_observers_on_create
    return if Current.team.blank?

    Extends::TEAM_AUTOMATIONS_OBSERVERS_CONFIG[self.class.base_class.name].each { |observer| observer.constantize.on_create(self, changed_by) }
  end

  def notify_observers_on_update
    return if Current.team.blank?

    Extends::TEAM_AUTOMATIONS_OBSERVERS_CONFIG[self.class.base_class.name].each { |observer| observer.constantize.on_update(self, changed_by) }
  end

  def notify_observers_on_destroy
    return if Current.team.blank?

    Extends::TEAM_AUTOMATIONS_OBSERVERS_CONFIG[self.class.base_class.name].each { |observer| observer.constantize.on_destroy(self, changed_by) }
  end
end
