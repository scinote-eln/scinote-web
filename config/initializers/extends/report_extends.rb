#########################################################
# EXTENDS METHODS. Here you can extend the arrays,      #
# hashes,.. which is used in methods. Please specify    #
# the method name and location!                         #
#########################################################

module ReportExtends
  # path: app/controllers/concerns/ReportActions
  # method: generate_module_contents_json

  # ModuleElement struct creates an argument objects which is needed in
  # generate_module_contents_json method. It takes 3 parameters a Proc and
  # additional options wich can be extended.
  # :values => name of the hook/identifier for specific module element state
  # :element => name of module element in plural
  # :children => bolean if element has children elements in report
  # :locals => an array of names of local variables which are passed in the view
  # :coll => a procedure which the my_module is passed and have to return a
  #          collection of elements
  # :singular => true by defaut; change the enum type to singular - needed when
  #              querying partials by name
  # :has_many => false by default; whether the element can have many
  #              manifestations, and its id will be appended.

  ModuleElement = Struct.new(:values,
                             :element,
                             :children,
                             :locals,
                             :coll,
                             :singular,
                             :has_many) do
    def initialize(values,
                   element,
                   children,
                   locals,
                   coll = nil,
                   singular = true,
                   has_many = false)
      super(values, element, children, locals, coll, singular, has_many)
    end

    def collection(my_module, params2)
      coll.call(my_module, params2) if coll
    end

    def parse_locals(values)
      container = {}
      locals.each_with_index do |local, index|
        container[local] = values[index]
      end
      container
    end

    def file_name
      return element.to_s unless singular
      element.to_s.singularize
    end
  end

  # Module contents element
  MODULE_CONTENTS = [
    ModuleElement.new([:protocol],
                      :protocol,
                      false,
                      [:my_module]),
    ModuleElement.new(%i(completed_steps uncompleted_steps),
                      :steps,
                      true,
                      [:step],
                      proc do |my_module, params2|
                        steps = []
                        steps << true if params2["module_completed_steps"] == '1'
                        steps << false if params2["module_uncompleted_steps"] == '1'
                        my_module.protocol.steps.where(completed: steps).order(:position)
                      end),
    ModuleElement.new([:result_assets],
                      :result_assets,
                      true,
                      [:result],
                      proc do |my_module|
                        my_module.results.joins(:result_asset).select(&:active?)
                      end),
    ModuleElement.new([:result_tables],
                      :result_tables,
                      true,
                      [:result],
                      proc do |my_module|
                        my_module.results.joins(:result_table).select(&:active?)
                      end),
    ModuleElement.new([:result_texts],
                      :result_texts,
                      true,
                      [:result],
                      proc do |my_module|
                        my_module.results.joins(:result_text).select(&:active?)
                      end),
    ModuleElement.new([:activity],
                      :activity,
                      false,
                      %i(my_module order)),
    ModuleElement.new([:repository],
                      :repository,
                      false,
                      %i(my_module order),
                      nil,
                      true,
                      true)
  ]

  # path: app/helpers/reports_helpers.rb
  # method: render_report_element

  # adds :order local to listed elements views
  # ADD REPORT ELEMENT TYPE WHICH YOU WANT TO PASS 'ORDER' LOCAL IN THE PARTIAL
  SORTED_ELEMENTS = %w(my_module_activity
                       my_module_repository
                       step_comments
                       result_comments)
  # sets local :my_module to the listed my_module child elements
  MY_MODULE_ELEMENTS = %w(my_module
                          my_module_protocol
                          my_module_activity
                          my_module_repository)

  # sets local name to first element of the listed elements
  FIRST_PART_ELEMENTS = %w(result_comments
                           result_text
                           result_asset
                           result_table
                           project_header
                           step_comments)

  MY_MODULE_CHILDREN_ELEMENTS = %w(step result_asset result_table result_text)

  # path: app/models/report_element.rb
  # method: set_element_reference

  ElementReference = Struct.new(:checker, :elements) do
    def initialize(checker, elements = :element_reference_needed!)
      super(checker, elements)
    end

    def check(report_element)
      checker.call(report_element)
    end
  end

  SET_ELEMENT_REFERENCES_LIST = [
    ElementReference.new(
      proc do |report_element|
        report_element.project_header? ||
          report_element.project_activity? ||
          report_element.project_samples?
      end,
      ['project_id']
    ),
    ElementReference.new(proc(&:experiment?), ['experiment_id']),
    ElementReference.new(
      proc do |report_element|
        report_element.my_module? ||
          report_element.my_module_protocol? ||
          report_element.my_module_activity? ||
          report_element.my_module_samples?
      end,
      ['my_module_id']
    ),
    ElementReference.new(
      proc(&:my_module_repository?),
      %w(my_module_id repository_id)
    ),
    ElementReference.new(
      proc do |report_element|
        report_element.step? || report_element.step_comments?
      end,
      ['step_id']
    ),
    ElementReference.new(
      proc do |report_element|
        report_element.result_asset? ||
          report_element.result_table? ||
          report_element.result_text? ||
          report_element.result_comments?
      end,
      ['result_id']
    ),
    ElementReference.new(proc(&:step_checklist?), ['checklist_id']),
    ElementReference.new(proc(&:step_asset?), ['asset_id']),
    ElementReference.new(proc(&:step_table?), ['table_id'])
  ]

  # path: app/models/report_element.rb
  # method: element_reference

  ELEMENT_REFERENCES = [
    ElementReference.new(
      proc do |report_element|
        report_element.project_header? ||
          report_element.project_activity? ||
          report_element.project_samples?
      end,
      ['project_id']
    ),
    ElementReference.new(proc(&:experiment?), ['experiment_id']),
    ElementReference.new(
      proc do |report_element|
        report_element.my_module? ||
          report_element.my_module_protocol? ||
          report_element.my_module_activity? ||
          report_element.my_module_samples?
      end,
      ['my_module_id']
    ),
    ElementReference.new(
      proc(&:my_module_repository?),
      %w(my_module_id repository_id)
    ),
    ElementReference.new(
      proc do |report_element|
        report_element.step? ||
          report_element.step_comments?
      end,
      ['step_id']
    ),
    ElementReference.new(
      proc do |report_element|
        report_element.result_asset? ||
          report_element.result_table? ||
          report_element.result_text? ||
          report_element.result_comments?
      end,
      ['result_id']
    ),
    ElementReference.new(proc(&:step_checklist?), ['checklist_id']),
    ElementReference.new(proc(&:step_asset?), ['asset_id']),
    ElementReference.new(proc(&:step_table?), ['table_id'])
  ]
end
