# frozen_string_literal: true

class FillEmptyProtocolNamesForLinkedTaskProtocols < ActiveRecord::Migration[6.1]
  def up
    execute(
      "UPDATE protocols " \
      "SET name = parent_protocols.name "\
      "FROM protocols parent_protocols "\
      "WHERE \"parent_protocols\".\"id\" = \"protocols\".\"parent_id\" "\
      "AND \"protocols\".\"protocol_type\" = #{Protocol.protocol_types['linked']} "\
      "AND \"protocols\".\"name\" IS NULL;"
    )
  end
end
