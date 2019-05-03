require File.expand_path('app/helpers/database_helper')
include DatabaseHelper

class AddPgTrgmSupport < ActiveRecord::Migration[4.2]
  def up
    if db_adapter_is? "PostgreSQL" then
      enable_extension :pg_trgm
    end
  end
end
