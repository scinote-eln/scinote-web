require File.expand_path('app/helpers/database_helper')
include DatabaseHelper

class AddPgTrgmSupport < ActiveRecord::Migration[4.2]
  def up
    enable_extension :pg_trgm
  end
end
