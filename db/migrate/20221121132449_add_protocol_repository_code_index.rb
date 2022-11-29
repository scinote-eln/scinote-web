# frozen_string_literal: true

class AddProtocolRepositoryCodeIndex < ActiveRecord::Migration[6.1]
  def up
    ActiveRecord::Base.connection.execute(
      "CREATE INDEX index_protocol_repository_on_protocol_repository_code ON "\
      "protocols using gin (('PT'::text || id) gin_trgm_ops);"
    )
  end

  def down
    remove_index :protocols, name: 'index_protocol_repository_on_protocol_repository_code'
  end
end
