# frozen_string_literal: true

class OpenVectorEditorService
  class << self
    def enabled?
      ENV.fetch('SCINOTE_OVE_ENABLED') == 'true'
    end
  end
end
