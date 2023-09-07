# frozen_string_literal: true

class Table < ApplicationRecord
  include SearchableModel

  auto_strip_attributes :name, nullify: false
  validates :name,
            length: { maximum: Constants::NAME_MAX_LENGTH }
  validates :contents,
            presence: true,
            length: { maximum: Constants::TABLE_JSON_MAX_SIZE_MB.megabytes }

  belongs_to :created_by,
             foreign_key: 'created_by_id',
             class_name: 'User',
             optional: true
  belongs_to :last_modified_by,
             foreign_key: 'last_modified_by_id',
             class_name: 'User',
             optional: true
  belongs_to :team, optional: true
  has_one :step_table, inverse_of: :table, dependent: :destroy
  has_one :step, through: :step_table

  has_one :result_table, inverse_of: :table, dependent: :destroy
  has_one :result, through: :result_table
  has_many :report_elements, inverse_of: :table, dependent: :destroy

  after_save :update_ts_index
  after_save { result&.touch; step&.touch }

  def self.search(user,
                  include_archived,
                  query = nil,
                  page = 1,
                  _current_team = nil,
                  options = {})
    step_ids = Step.search(user, include_archived, nil, Constants::SEARCH_NO_LIMIT)
                   .joins(:step_tables)
                   .distinct
                   .pluck('step_tables.id')

    result_ids = Result.search(user, include_archived, nil, Constants::SEARCH_NO_LIMIT)
                       .joins(:result_tables)
                       .distinct
                       .pluck('result_tables.id')

    table_query = Table.distinct
                       .left_outer_joins(:step_table, :result_table, :result)
                       .where('step_tables.id IN (?) OR result_tables.id IN (?)', step_ids, result_ids)

    if options[:whole_word].to_s == 'true' ||
       options[:whole_phrase].to_s == 'true'
      like = options[:match_case].to_s == 'true' ? '~' : '~*'
      s_query = query.gsub(/[!()&|:]/, ' ')
                     .strip
                     .split(/\s+/)
                     .map { |t| t + ':*' }
      if options[:whole_word].to_s == 'true'
        a_query = query.split
                       .map { |a| Regexp.escape(a) }
                       .join('|')
        s_query = s_query.join('|')
      else
        a_query = Regexp.escape(query)
        s_query = s_query.join('&')
      end
      a_query = '\\y(' + a_query + ')\\y'
      s_query = s_query.tr('\'', '"')

      new_query = table_query.where(
        "(trim_html_tags(tables.name) #{like} ?" \
        "OR tables.data_vector @@ to_tsquery(?))",
        a_query,
        s_query
      )
    else
      like = options[:match_case].to_s == 'true' ? 'LIKE' : 'ILIKE'
      a_query = query.split.map { |a| "%#{sanitize_sql_like(a)}%" }

      # Trim whitespace and replace it with OR character. Make prefixed
      # wildcard search term and escape special characters.
      # For example, search term 'demo project' is transformed to
      # 'demo:*|project:*' which makes word inclusive search with postfix
      # wildcard.
      s_query = query.gsub(/[!()&|:]/, ' ')
                     .strip
                     .split(/\s+/)
                     .map { |t| t + ':*' }
                     .join('|')
                     .tr('\'', '"')
      new_query = table_query.where(
        "(trim_html_tags(tables.name) #{like} ANY (array[?])" \
        "OR tables.data_vector @@ to_tsquery(?))",
        a_query,
        s_query
      )
    end

    # Show all results if needed
    if page == Constants::SEARCH_NO_LIMIT
      new_query
    else
      new_query.limit(Constants::SEARCH_LIMIT).offset((page - 1) * Constants::SEARCH_LIMIT)
    end
  end

  def metadata
    attributes['metadata'].is_a?(String) ? JSON.parse(attributes['metadata']) : attributes['metadata']
  end

  def contents_utf_8
    contents.present? ? contents.force_encoding(Encoding::UTF_8) : nil
  end

  def update_ts_index
    if saved_change_to_contents?
      sql = "UPDATE tables " +
            "SET data_vector = " +
            "to_tsvector(substring(encode(contents::bytea, 'escape'), 9)) " +
            "WHERE id = " + Integer(id).to_s
      Table.connection.execute(sql)
    end
  end

  def to_csv
    require 'csv'

    data = JSON.parse(contents)['data']
    CSV.generate do |csv|
     data.each do |row|
       csv << row
     end
    end
  end

  def duplicate(parent, user, position = nil)
    case parent
    when Step
      ActiveRecord::Base.transaction do
        new_table = parent.tables.create!(
          name: name,
          contents: contents.encode('UTF-8', 'UTF-8'),
          team: parent.protocol.team,
          created_by: user,
          metadata: metadata,
          last_modified_by: user
        )

        parent.step_orderable_elements.create!(
          position: position || parent.step_orderable_elements.length,
          orderable: new_table.step_table
        )

        new_table
      end
    when Result
      ActiveRecord::Base.transaction do
        new_table = parent.tables.create!(
          name: name,
          contents: contents.encode('UTF-8', 'UTF-8'),
          team: parent.my_module.team,
          created_by: user,
          metadata: metadata,
          last_modified_by: user
        )

        parent.result_orderable_elements.create!(
          position: position || parent.result_orderable_elements.length,
          orderable: new_table.result_table
        )

        new_table
      end
    end
  end
end
