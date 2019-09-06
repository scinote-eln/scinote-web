# frozen_string_literal: true

class ProtocolProtocolKeyword < ApplicationRecord
  after_create :increment_protocols_count
  after_destroy :decrement_protocols_count

  validates :protocol, presence: true
  validates :protocol_keyword, presence: true

  belongs_to :protocol, inverse_of: :protocol_protocol_keywords
  belongs_to :protocol_keyword, inverse_of: :protocol_protocol_keywords

  private

  def increment_protocols_count
    self.protocol_keyword.increment!(:nr_of_protocols)
  end

  def decrement_protocols_count
    self.protocol_keyword.decrement!(:nr_of_protocols)
    if self.protocol_keyword.nr_of_protocols == 0 then
      self.protocol_keyword.destroy
    end
  end
end
