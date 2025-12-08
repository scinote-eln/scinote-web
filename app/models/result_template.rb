# frozen_string_literal: true

class ResultTemplate < ResultBase
  belongs_to :protocol, inverse_of: :results
  delegate :team, to: :protocol

  scope :active, -> { self } # Template can't be archived

  SEARCHABLE_ATTRIBUTES = ['results.name'].freeze

  def self.search(user,
                  _include_archived,
                  query = nil,
                  teams = user.teams,
                  _options = {})
    new_query = joins(:protocol)
                .where(
                  protocols: {
                    id: Protocol.with_granted_permissions(user, ProtocolPermissions::READ, teams).select(:id)
                  }
                )
    new_query.where_attributes_like_boolean(SEARCHABLE_ATTRIBUTES, query)
  end

  def self.where_children_attributes_like(query, _options = {})
    from(
      "(#{joins(:result_texts).where_attributes_like(ResultText::SEARCHABLE_ATTRIBUTES, query).to_sql}
      UNION
      #{joins(result_tables: :table).where_attributes_like(Table::SEARCHABLE_ATTRIBUTES, query).to_sql}
      AS results",
      :results
    )
  end

  def self.readable_by_user(user, teams)
    where(protocol: Protocol.readable_by_user(user, teams))
  end

  def self.filter_by_teams(teams = [])
    return self if teams.blank?

    joins(:protocol).where(protocol: { team: teams })
  end

  def parent
    protocol
  end

  def archived?
    false
  end
end
