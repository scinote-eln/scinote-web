class Step < ApplicationRecord
  include SearchableModel
  include SearchableByNameModel
  include TinyMceImages
  include ViewableModel

  enum assets_view_mode: { thumbnail: 0, list: 1, inline: 2 }

  auto_strip_attributes :name, :description, nullify: false
  validates :name,
            presence: true,
            length: { maximum: Constants::NAME_MAX_LENGTH }
  validates :description, length: { maximum: Constants::RICH_TEXT_MAX_LENGTH }
  validates :position, presence: true
  validates :completed, inclusion: { in: [true, false] }
  validates :user, :protocol, presence: true
  validates :completed_on, presence: true, if: proc { |s| s.completed? }
  validates :position, uniqueness: { scope: :protocol }, if: :position_changed?

  before_validation :set_completed_on, if: :completed_changed?
  before_save :set_last_modified_by
  before_destroy :cascade_before_destroy
  after_destroy :adjust_positions_after_destroy

  belongs_to :user, inverse_of: :steps
  belongs_to :last_modified_by, foreign_key: 'last_modified_by_id', class_name: 'User', optional: true
  belongs_to :protocol, inverse_of: :steps, touch: true
  has_many :checklists, inverse_of: :step, dependent: :destroy
  has_many :step_comments, foreign_key: :associated_id, dependent: :destroy
  has_many :step_assets, inverse_of: :step, dependent: :destroy
  has_many :assets, through: :step_assets
  has_many :step_tables, inverse_of: :step, dependent: :destroy
  has_many :tables, through: :step_tables
  has_many :report_elements, inverse_of: :step, dependent: :destroy

  accepts_nested_attributes_for :checklists,
                                reject_if: :all_blank,
                                allow_destroy: true
  accepts_nested_attributes_for :assets,
                                reject_if: :all_blank,
                                allow_destroy: true
  accepts_nested_attributes_for :tables,
                                reject_if: proc { |attributes|
                                  attributes['contents'].blank?
                                },
                                allow_destroy: true

  def self.search(user,
                  include_archived,
                  query = nil,
                  page = 1,
                  _current_team = nil,
                  options = {})
    protocol_ids = Protocol.search(user, include_archived, nil, Constants::SEARCH_NO_LIMIT)
                           .pluck(:id)

    new_query = Step.distinct
                    .where(steps: { protocol_id: protocol_ids })
                    .where_attributes_like(%i(name description), query, options)

    # Show all results if needed
    if page == Constants::SEARCH_NO_LIMIT
      new_query
    else
      new_query.limit(Constants::SEARCH_LIMIT).offset((page - 1) * Constants::SEARCH_LIMIT)
    end
  end

  def default_view_state
    { 'assets' => { 'sort' => 'new' } }
  end

  def validate_view_state(view_state)
    unless %w(new old atoz ztoa).include?(view_state.state.dig('assets', 'sort'))
      view_state.errors.add(:state, :wrong_state)
    end
  end

  def self.viewable_by_user(user, teams)
    where(protocol: Protocol.viewable_by_user(user, teams))
  end

  def can_destroy?
    !assets.map(&:locked?).any?
  end

  def my_module
    protocol.present? ? protocol.my_module : nil
  end

  def position_plus_one
    position + 1
  end

  def last_comments(last_id = 1, per_page = Constants::COMMENTS_SEARCH_LIMIT)
    last_id = Constants::INFINITY if last_id <= 1
    comments = StepComment.joins(:step)
                          .where(steps: { id: id })
                          .where('comments.id <  ?', last_id)
                          .order(created_at: :desc)
                          .limit(per_page)
    StepComment.from(comments, :comments).order(created_at: :asc)
  end

  def space_taken
    st = 0
    assets.each do |asset|
      st += asset.estimated_size
    end
    st
  end

  def asset_position(asset)
    assets.order(:updated_at).each_with_index do |step_asset, i|
      return { count: assets.count, pos: i } if asset.id == step_asset.id
    end
  end

  def move_up
    return if position.zero?

    move_in_protocol(:up)
  end

  def move_down
    return if position == protocol.steps.count - 1

    move_in_protocol(:down)
  end

  def comments
    step_comments
  end

  private

  def move_in_protocol(direction)
    transaction do
      re_index_following_steps

      case direction
      when :up
        new_position = position - 1
      when :down
        new_position = position + 1
      else
        return
      end

      step_to_swap = protocol.steps.find_by(position: new_position)
      position_to_swap = position

      if step_to_swap
        step_to_swap.update!(position: -1)
        update!(position: new_position)
        step_to_swap.update!(position: position_to_swap)
      else
        update!(position: new_position)
      end
    end
  end

  def adjust_positions_after_destroy
    re_index_following_steps
    protocol.steps.where('position > ?', position).order(:position).each do |step|
      step.update!(position: step.position - 1)
    end
  end

  def re_index_following_steps
    steps = protocol.steps.where(position: position..).order(:position).where.not(id: id)
    i = position
    steps.each do |step|
      i += 1
      step.position = i
    end

    steps.reverse_each do |step|
      step.save! if step.position_changed?
    end
  end

  def cascade_before_destroy
    assets.each(&:destroy)
    tables.each(&:destroy)
  end

  def set_completed_on
    return if completed? && completed_on.present?

    self.completed_on = completed? ? DateTime.now : nil
  end

  def set_last_modified_by
    self.last_modified_by_id ||= user_id
  end
end
