# frozen_string_literal: true

class Result < ResultBase
  include ArchivableModel
  include ObservableModel
  include PinningModel

  belongs_to :archived_by, class_name: 'User', optional: true
  belongs_to :restored_by, class_name: 'User', optional: true
  belongs_to :my_module, inverse_of: :results
  belongs_to :pinned_by, class_name: 'User', optional: true
  has_many :result_comments, inverse_of: :result, foreign_key: :associated_id, dependent: :destroy
  has_many :report_elements, inverse_of: :result, dependent: :destroy

  SEARCHABLE_ATTRIBUTES = ['results.name', :children].freeze

  delegate :team, to: :my_module

  scope :archived_or_having_archived, lambda {
    with_elements = left_outer_joins(:result_texts, :assets, :tables)
    with_elements.archived.or(
      with_elements.where(result_texts: { archived: true })
                  .or(with_elements.where(assets: { archived: true }))
                  .or(with_elements.where(tables: { archived: true }))
    )
  }

  def self.search(user,
                  include_archived,
                  query = nil,
                  teams = user.teams,
                  _options = {})
    readable_results = joins(:my_module).where(my_modules: { id: MyModule.readable_by_user(user, teams).select(:id) })
    results = joins(:my_module)

    unless include_archived
      results = results.joins(my_module: { experiment: :project })
                       .active
                       .where(my_modules: { archived: false },
                              experiments: { archived: false },
                              projects: { archived: false })
    end

    results = results.with(readable_results: readable_results)
                     .joins('INNER JOIN "readable_results" ON "readable_results"."id" = "results"."id"')

    results.where_attributes_like_boolean(SEARCHABLE_ATTRIBUTES, query, { include_archived: include_archived })
  end

  def self.where_children_attributes_like(query, options = {})
    unscoped_readable_results = unscoped.joins('INNER JOIN "readable_results" ON "readable_results"."id" = "results"."id"').select(:id, :type)
    if options[:include_archived]
      text_sql = unscoped_readable_results.joins(:result_texts).where_attributes_like(ResultText::SEARCHABLE_ATTRIBUTES, query).to_sql

      table_sql = unscoped_readable_results.joins(result_tables: :table).where_attributes_like(Table::SEARCHABLE_ATTRIBUTES, query).to_sql
    else
      text_sql = unscoped_readable_results.joins(:result_texts)
                                          .where(result_texts: { archived: false })
                                          .where_attributes_like(ResultText::SEARCHABLE_ATTRIBUTES, query)
                                          .to_sql

      table_sql = unscoped_readable_results.joins(result_tables: :table)
                                           .where(tables: { archived: false })
                                           .where_attributes_like(Table::SEARCHABLE_ATTRIBUTES, query)
                                           .to_sql
    end

    comment_sql = unscoped_readable_results.joins(:result_comments).where_attributes_like(ResultComment::SEARCHABLE_ATTRIBUTES, query).to_sql

    unscoped.from("(#{text_sql} UNION #{table_sql} UNION #{comment_sql}) AS results", :results)
  end

  def self.readable_by_user(user, teams)
    where(my_module: MyModule.readable_by_user(user, teams))
  end

  def self.filter_by_teams(teams = [])
    return self if teams.blank?

    joins(my_module: { experiment: :project }).where(my_module: { experiments: { projects: { team: teams } } })
  end

  def all_elements
    result_texts + tables
  end

  def active_elements
    result_texts.active + tables.active
  end

  def active_elements_ordered
    (
      result_texts.joins(:result_orderable_element).active.select('result_texts.*, result_orderable_elements.position as position') +
      tables.joins(result_table: :result_orderable_element).active.select('tables.*, result_orderable_elements.position as position')
    ).sort_by(&:position)
  end

  def archived_elements
    result_texts.archived + tables.archived
  end

  def has_archived_element?
    result_texts.archived.any? || tables.archived.any?
  end

  def parent
    my_module
  end

  def navigable?
    !my_module.archived? && my_module.navigable?
  end

  def last_comments(last_id = 1, per_page = Constants::COMMENTS_SEARCH_LIMIT)
    last_id = Constants::INFINITY if last_id <= 1
    comments = ResultComment.joins(:result)
                            .where(results: { id: id })
                            .where('comments.id <  ?', last_id)
                            .order(created_at: :desc)
                            .limit(per_page)
    ResultComment.from(comments, :comments).order(created_at: :asc)
  end

  def is_text
    raise StandardError, 'Deprecated method, needs to be replaced!'
  end

  def is_table
    raise StandardError, 'Deprecated method, needs to be replaced!'
  end

  def is_asset
    raise StandardError, 'Deprecated method, needs to be replaced!'
  end

  def comments
    result_comments
  end

  private

  # Override for ObservableModel
  def changed_by
    last_modified_by || user
  end
end
