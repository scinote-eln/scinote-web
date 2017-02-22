class Settings < ActiveRecord::Base
  def self.instance
    @instance ||= first
    @instance ||= new
  end
end
