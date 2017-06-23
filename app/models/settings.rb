class Settings < ApplicationRecord
  def self.instance
    @instance ||= first
    @instance ||= new
  end
end
