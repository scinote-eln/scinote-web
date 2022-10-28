# frozen_string_literal: true

module CardsViewHelper
  def cards_view_type_class(view_type)
    view_type == 'table' ? 'list' : 'cards'
  end
end
