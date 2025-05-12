class RemoveKeywordsFromModuleProtocols < ActiveRecord::Migration[4.2]
  class TempProtocol < ApplicationRecord
    self.table_name = 'protocols'

    has_many :protocol_protocol_keywords, foreign_key: :protocol_id
    has_many :protocol_keywords, through: :protocol_protocol_keywords
  end

  def up
    TempProtocol.find_each do |p|
      if p.in_module? then
        p.protocol_keywords.destroy_all
      end
    end
  end
end
