class Settings < ActiveRecord::Base
  @instance = first

  def self.instance
    @instance ||= new
  end
end
