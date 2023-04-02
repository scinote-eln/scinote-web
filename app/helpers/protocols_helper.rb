# frozen_string_literal: true

module ProtocolsHelper
  def templates_view_mode_archived?(type: nil, protocol: nil)
    type == :archived || protocol&.archived?
  end
end
