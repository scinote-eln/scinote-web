class Report < ActiveRecord::Base
  include SearchableModel

  validates :name,
            length: { minimum: NAME_MIN_LENGTH, maximum: NAME_MAX_LENGTH },
            uniqueness: { scope: [:user, :project], case_sensitive: false }
  validates :description, length: { maximum: TEXT_MAX_LENGTH }
  validates :project, presence: true
  validates :user, presence: true

  belongs_to :project, inverse_of: :reports
  belongs_to :user, inverse_of: :reports
  belongs_to :last_modified_by, foreign_key: 'last_modified_by_id', class_name: 'User'

  # Report either has many report elements (if grouped by timestamp),
  # or many module elements (if grouped by module)
  has_many :report_elements, inverse_of: :report, dependent: :destroy

  def self.search(
    user,
    include_archived,
    query = nil,
    page = 1
  )

    project_ids =
      Project
      .search(user, include_archived, nil, SHOW_ALL_RESULTS)
      .select("id")

    if query
      a_query = query.strip
      .gsub("_","\\_")
      .gsub("%","\\%")
      .split(/\s+/)
      .map {|t|  "%" + t + "%" }
    else
      a_query = query
    end

    new_query = Report
      .distinct
      .joins("LEFT OUTER JOIN users ON users.id = reports.user_id OR users.id = reports.last_modified_by_id")
      .where("reports.project_id IN (?)", project_ids)
      .where("reports.user_id = (?)", user.id)
      .where_attributes_like(
        [
          :name,
          :description
        ],
        a_query
      )

    # Show all results if needed
    if page == SHOW_ALL_RESULTS
      new_query
    else
      new_query
        .limit(SEARCH_LIMIT)
        .offset((page - 1) * SEARCH_LIMIT)
    end
  end

  def root_elements
    (report_elements.order(:position)).select { |el| el.parent.blank? }
  end

  # Save the JSON represented contents to this report
  # (this action will overwrite any existing report elements)
  def save_with_contents(json_contents)
    begin
      Report.transaction do
        #First, save the report itself
        save!

        # Secondly, delete existing report elements
        report_elements.destroy_all

        # Lastly, iterate through contents
        json_contents.each_with_index do |json_el, i|
          save_json_element(json_el, i, nil)
        end
      end
    rescue ActiveRecord::ActiveRecordError, ArgumentError
      return false
    end
    return true
  end

  # Clean report elements from report
  # the function runs before the report is edit
  def cleanup_report
    report_elements.each do |el|
      el.clean_removed_or_archived_elements
    end
  end

  private

  # Recursively save a single JSON element
  def save_json_element(json_element, index, parent)
    el = ReportElement.new
    el.position = index
    el.report = self
    el.parent = parent
    el.type_of = json_element["type_of"]
    el.sort_order = json_element["sort_order"]
    el.set_element_reference(json_element["id"])
    el.save!
    if json_element["children"].present?
      json_element["children"].each_with_index do |child, i|
        save_json_element(child, i, el)
      end
    end
  end
end
