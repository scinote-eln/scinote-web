module ProtocolsHelper
  def templates_view_mode_archived?
    @type == :archived || @protocol&.archived?
  end
end
