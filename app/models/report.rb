class Report < ApplicationRecord
  include SearchableModel

  auto_strip_attributes :name, :description, nullify: false
  validates :name,
            length: { minimum: Constants::NAME_MIN_LENGTH,
                      maximum: Constants::NAME_MAX_LENGTH },
            uniqueness: { scope: [:user, :project], case_sensitive: false }
  validates :description, length: { maximum: Constants::TEXT_MAX_LENGTH }
  validates :project, presence: true
  validates :user, presence: true

  belongs_to :project, inverse_of: :reports, optional: true
  belongs_to :user, inverse_of: :reports, optional: true
  belongs_to :team, inverse_of: :reports
  belongs_to :last_modified_by,
             foreign_key: 'last_modified_by_id',
             class_name: 'User',
             optional: true

  # Report either has many report elements (if grouped by timestamp),
  # or many module elements (if grouped by module)
  has_many :report_elements, inverse_of: :report, dependent: :delete_all

  after_commit do
    Views::Datatables::DatatablesReport.refresh_materialized_view
  end

  def self.search(
    user,
    include_archived,
    query = nil,
    page = 1,
    _current_team = nil,
    options = {}
  )

    project_ids =
      Project
      .search(user, include_archived, nil, Constants::SEARCH_NO_LIMIT)
      .pluck(:id)

    new_query =
      Report
      .distinct
      .joins('LEFT OUTER JOIN users ON users.id = reports.user_id ' \
             'OR users.id = reports.last_modified_by_id')
      .where('reports.project_id IN (?)', project_ids)
      .where('reports.user_id = (?)', user.id)
      .where_attributes_like([:name, :description], query, options)

    # Show all results if needed
    if page == Constants::SEARCH_NO_LIMIT
      new_query
    else
      new_query
        .limit(Constants::SEARCH_LIMIT)
        .offset((page - 1) * Constants::SEARCH_LIMIT)
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

  def self.generate_whole_project_report(project, current_user, current_team)
    report_contents = []
    report_contents << {
      'type_of' => 'project_header',
      'id' => {
        'project_id' => project.id
      },
      'sort_order' => nil,
      'children' => []
    }

    project.experiments.each do |exp|
      modules = []

      exp.my_modules.each do |my_module|
        module_children = []

        my_module.protocol.steps.each do |step|
          step_children = []

          step.assets.each do |asset|
            step_children << {
              'type_of' => 'step_asset',
              'id' => {
                'asset_id' => asset.id
              },
              'sort_order' => nil,
              'children' => []
            }
          end
          step.tables.each do |table|
            step_children << {
              'type_of' => 'step_table',
              'id' => {
                'table_id' => table.id
              },
              'sort_order' => nil,
              'children' => []
            }
          end
          step.checklists.each do |step_checklist|
            step_children << {
              'type_of' => 'step_checklist',
              'id' => {
                'checklist_id' => step_checklist.id
              },
              'sort_order' => nil,
              'children' => []
            }
          end
          if step.step_comments.any?
            step_children << {
              'type_of' => 'step_comments',
              'id' => {
                'step_id' => step.id
              },
              'sort_order' => 'asc',
              'children' => []
            }
          end

          module_children << {
            'type_of' => 'step',
            'id' => {
              'step_id' => step.id
            },
            'sort_order' => nil,
            'children' => step_children
          }
        end

        my_module.results.each do |result|
          if result.asset
            result_comments = []

            if result.result_comments.any?
              result_comments << {
                'type_of' => 'result_comments',
                'id' => {
                  'result_id' => result.id
                },
                'sort_order' => 'asc',
                'children' => []
              }
            end

            module_children << {
              'type_of' => 'result_asset',
              'id' => {
                'result_id' => result.id
              },
              'sort_order' => nil,
              'children' => []
            }
          elsif result.table
            result_comments = []

            if result.result_comments.any?
              result_comments << {
                'type_of' => 'result_comments',
                'id' => {
                  'result_id' => result.id
                },
                'sort_order' => 'asc',
                'children' => []
              }
            end

            module_children << {
              'type_of' => 'result_table',
              'id' => {
                'result_id' => result.id
              },
              'sort_order' => nil,
              'children' => result_comments
            }
          elsif result.result_text
            result_comments = []

            if result.result_comments.any?
              result_comments << {
                'type_of' => 'result_comments',
                'id' => {
                  'result_id' => result.id
                },
                'sort_order' => 'asc',
                'children' => []
              }
            end

            module_children << {
              'type_of' => 'result_text',
              'id' => {
                'result_id' => result.id
              },
              'sort_order' => nil,
              'children' => result_comments
            }
          end
        end

        if my_module.activities.any?
          module_children << {
            'type_of' => 'my_module_activity',
            'id' => {
              'my_module_id' => my_module.id
            },
            'sort_order' => 'asc',
            'children' => []
          }
        end

        module_repositories_id =
          my_module.repository_rows.map(&:repository_id).uniq
        module_repositories_id.each do |repo_id|
          module_children << {
            'type_of' => 'my_module_repository',
            'id' => {
              'my_module_id' => my_module.id,
              'repository_id' => repo_id
            },
            'sort_order' => 'asc',
            'children' => []
          }
        end

        modules << {
          'type_of' => 'my_module',
          'id' => {
            'my_module_id' => my_module.id
          },
          'sort_order' => nil,
          'children' => module_children
        }
      end

      report_contents << {
        'type_of' => 'experiment',
        'id' => {
          'experiment_id' => exp.id
        },
        'sort_order' => nil,
        'children' => modules
      }
    end

    dummy_name = loop do
      dummy_name = SecureRandom.hex(10)
      break dummy_name unless Report.where(name: dummy_name).exists?
    end

    report = Report.new
    report.name = dummy_name
    report.project = project
    report.user = current_user
    report.team = current_team
    report.last_modified_by = current_user

    report.save_with_contents(report_contents)
    report
  end

  private

  # Recursively save a single JSON element
  def save_json_element(json_element, index, parent)
    el = ReportElement.new
    el.position = index
    el.report = self
    el.parent = parent
    el.type_of = json_element['type_of']
    el.sort_order = json_element['sort_order']
    el.set_element_references(json_element['id'])
    el.save!

    if json_element['children'].present?
      json_element['children'].each_with_index do |child, i|
        save_json_element(child, i, el)
      end
    end
  end
end
