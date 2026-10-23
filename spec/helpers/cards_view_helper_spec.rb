# frozen_string_literal: true

require 'rails_helper'

describe CardsViewHelper, type: :helper do
  describe '#cards_view_type_class' do
    it 'returns list for the table view' do
      expect(helper.cards_view_type_class('table')).to eq 'list'
    end

    it 'returns cards for any other view' do
      expect(helper.cards_view_type_class('cards')).to eq 'cards'
      expect(helper.cards_view_type_class(nil)).to eq 'cards'
    end
  end
end
