# frozen_string_literal: true

class OpenVectorEditorService
  class << self
    def enabled?
      ove_enabled_until = ENV.fetch('SCINOTE_OVE_ENABLED_UNTIL', nil)

      return false if ove_enabled_until.blank?

      DateTime.now.utc.to_date < DateTime.strptime(ove_enabled_until, '%d-%m-%Y').utc.to_date
    end

    def evaluation_period_left
      return 0 unless enabled?

      ove_enabled_until = ENV.fetch('SCINOTE_OVE_ENABLED_UNTIL', nil)

      return 0 if ove_enabled_until.blank?

      (DateTime.strptime(ove_enabled_until, '%d-%m-%Y').utc.to_date - DateTime.now.utc.to_date).to_i
    end
  end
end
