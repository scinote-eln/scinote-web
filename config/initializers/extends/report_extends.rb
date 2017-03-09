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
  # :element => name of module element in plural
  # :children => bolean if element has children elements in report
  # :locals => an array of names of local variables which are passed in the view
  # :coll => a prock which the my_module is passed and have to return a
  #          collection of element
  # :options => a hash of options for now only :add_values which
  #             will add a value to locals

  ModuleElement = Struct.new(:element,
                             :children,
                             :locals,
                             :coll) do
    def initialize(element, children, locals, coll = nil)
      super(element, children, locals, coll)
    end

    def collection(my_module)
      coll.call(my_module) if coll
    end

    def parse_locals(values)
      container = {}
      locals.each_with_index do |local, index|
        container[local] = values[index]
      end
      container
    end
  end

  # Module contents element
  MODULE_CONTENTS = [
    ModuleElement.new(:steps,
                      true,
                      [:step],
                      proc do |my_module|
                        my_module.protocol.completed_steps
                      end),
    ModuleElement.new(:result_assets,
                      true,
                      [:result],
                      proc do |my_module|
                        my_module.results.select { |r| r.is_asset && r.active? }
                      end),
    ModuleElement.new(:result_tables,
                      true,
                      [:result],
                      proc do |my_module|
                        my_module.results.select { |r| r.is_table && r.active? }
                      end),
    ModuleElement.new(:result_texts,
                      true,
                      [:result],
                      proc do |my_module|
                        my_module.results.select { |r| r.is_text && r.active? }
                      end),
    ModuleElement.new(:activity,
                      false,
                      [:my_module, :order]),
    ModuleElement.new(:samples,
                      false,
                      [:my_module, :order])
  ]

  # path: app/helpers/reports_helpers.rb
  # method: render_report_element

  # adds :order local to listed elements views
  # ADD REPORT ELEMENT TYPE WHICH YOU WANT TO PASS 'ORDER' LOCAL IN THE PARTIAL
  SORTED_ELEMENTS = %w(my_module_activity
                       my_module_samples
                       step_comments
                       result_comments)
  # sets local :my_module to the listed my_module child elements
  MY_MODULE_ELEMENTS = %w(my_module my_module_activity my_module_samples)

  # sets local name to first element of the listed elements
  RESULT_ELEMENTS = %w(result_comments
                       result_text
                       result_asset
                       result_table
                       project_header)

  # path: app/models/report_element.rb
  # method: set_element_reference

  ElementReference = Struct.new(:checker, :element) do
    def initialize(checker, element = :element_reference_needed!)
      super(checker, element)
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
      'project_id'
    ),
    ElementReference.new(proc(&:experiment?), 'experiment_id'),
    ElementReference.new(
      proc do |report_element|
        report_element.my_module? ||
          report_element.my_module_activity? ||
          report_element.my_module_samples?
      end,
      'my_module_id'
    ),
    ElementReference.new(
      proc do |report_element|
        report_element.step? || report_element.step_comments?
      end,
      'step_id'
    ),
    ElementReference.new(
      proc do |report_element|
        report_element.result_asset? ||
          report_element.result_table? ||
          report_element.result_text? ||
          report_element.result_comments?
      end,
      'result_id'
    ),
    ElementReference.new(proc(&:step_checklist?), 'checklist_id'),
    ElementReference.new(proc(&:step_asset?), 'asset_id'),
    ElementReference.new(proc(&:step_table?), 'table_id')
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
      'project_id'
    ),
    ElementReference.new(proc(&:experiment?), 'experiment_id'),
    ElementReference.new(
      proc do |report_element|
        report_element.my_module? ||
          report_element.my_module_activity? ||
          report_element.my_module_samples?
      end,
      'my_module_id'
    ),
    ElementReference.new(
      proc do |report_element|
        report_element.step? ||
          report_element.step_comments?
      end,
      'step_id'
    ),
    ElementReference.new(
      proc do |report_element|
        report_element.result_asset? ||
          report_element.result_table? ||
          report_element.result_text? ||
          report_element.result_comments?
      end,
      'result_id'
    ),
    ElementReference.new(proc(&:step_checklist?), 'checklist_id'),
    ElementReference.new(proc(&:step_asset?), 'asset_id'),
    ElementReference.new(proc(&:step_table?), 'table_id')
  ]
end
