require 'test_helper'

class ReportElementTest < ActiveSupport::TestCase

  test "should validate with valid data" do
    @re = generate_new_el(true)
    assert @re.valid?, "Valid report element is not valid"
  end

  test "should not validate with invalid position" do
    @re = generate_new_el(true)
    @re.position = nil
    assert_not @re.valid?, "Report element without position was valid"
  end

  test "should not validate without report" do
    @re = generate_new_el(true)
    @re.report = nil
    assert_not @re.valid?, "Report element without report was valid"

    @re.report_id = -1
    assert_not @re.valid?, "Report element with invalid report reference was valid"
  end

  test "should not validate without type_of" do
    @re = generate_new_el(true)
    @re.type_of = nil
    assert_not @re.valid?, "Report element without type_of was valid"
  end

  test "test element references" do
    @re = generate_new_el(true)
    @re.project = nil
    assert_not @re.valid?, "Report without any element reference was valid"

    @re.project = projects(:interfaces)
    @re.my_module = my_modules(:list_of_samples)
    assert_not @re.valid?, "Report with >1 element references was valid"

    # Test all types of elements
    re_vals_list = [
      { type_of: 0, id: projects(:interfaces).id },
      { type_of: 1, id: my_modules(:list_of_samples).id },
      { type_of: 2, id: steps(:step1).id },
      { type_of: 3, id: results(:two).id, result: true },
      { type_of: 4, id: results(:four).id, result: true },
      { type_of: 5, id: results(:one).id, result: true },
      { type_of: 6, id: my_modules(:list_of_samples).id },
      { type_of: 7, id: my_modules(:list_of_samples).id },
      { type_of: 8, id: checklists(:one).id },
      { type_of: 9, id: assets(:one).id },
      { type_of: 10, id: tables(:one).id },
      { type_of: 11, id: steps(:step1).id, comments: true },
      { type_of: 12, id: results(:one).id, comments: true }
    ]

    re_vals_list.each do |re_vals|
      re = generate_new_el(false)
      re.type_of = re_vals[:type_of]
      re.set_element_reference(re_vals[:id])
      assert re.valid?
      assert_equal re_vals[:id], re.element_reference.id
      assert re.result? if re_vals.include? :result
      assert re.comments? if re_vals.include? :comments
      assert_element_reference_present re
    end
  end

  private

  def generate_new_el(include_reference)
    re = ReportElement.new(
      position: 0,
      type_of: 0,
      sort_order: nil,
      report: reports(:one),
      project: projects(:interfaces)
    )
    unless include_reference then
      re.project = nil
    end
    re
  end

  def assert_element_reference_present(re)
    if re.project_header? or re.project_activity? or re.project_samples?
      assert re.project.present?
    elsif re.my_module? or re.my_module_activity? or re.my_module_samples?
      assert re.my_module.present?
    elsif re.step? or re.step_comments?
      assert re.step.present?
    elsif re.result_asset? or re.result_table? or re.result_text? or re.result_comments?
      assert re.result.present?
    elsif re.step_checklist?
      assert re.checklist.present?
    elsif re.step_asset?
      assert re.asset.present?
    elsif re.step_table?
      assert re.table.present?
    end
  end

end
