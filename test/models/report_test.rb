require 'test_helper'

class ReportTest < ActiveSupport::TestCase

  def setup
    @report = reports(:one)
    @json_el = {
      "type_of" => "result_comments",
      "sort_order" => "desc",
      "id" => results(:four).id,
    }
  end

  should validate_length_of(:name)
    .is_at_least(Constants::NAME_MIN_LENGTH)
    .is_at_most(Constants::NAME_MAX_LENGTH)

  should validate_length_of(:description)
    .is_at_most(Constants::TEXT_MAX_LENGTH)

  test "should validate with valid data" do
    assert @report.valid?, "Report with valid data was invalid"
  end

  test 'should not validate with invalid name' do
    # Check if uniqueness constraint works
    @report2 = Report.new(
      name: @report.name,
      project: projects(:interfaces),
      user: users(:steve)
    )

    assert_not @report2.valid?,
               'Report with same name for specific user was valid'
  end

  test "should not validate without project" do
    @report.project = nil
    assert_not @report.valid?, "Report without project reference was valid"
  end

  test "should not validate without user" do
    @report.user = nil
    assert_not @report.valid?, "Report without user reference was valid"
  end

  test "test root_elements function" do
    elements = @report.root_elements
    pos = -10000
    elements.each do |element|
      assert element.position >= pos, "Function root_elements doesn't sort elements properly"
      pos = element.position

      assert element.parent.blank?, "Function root_elements doesn't return elements without parents"
    end
  end

  test "test save_with_contents function" do
    # We shall only test if saving fails for sinigle json element variants
    # (saving of report itself was handled in previous tests).
    @report2 = new_valid_report
    @json_el2 = @json_el.deep_dup
    @json_el2.delete("type_of")
    assert_not @report2.save_with_contents([@json_el2]), "Report with invalid json_element (without type_of) was saved"

    @report2 = new_valid_report
    @json_el2 = @json_el.deep_dup
    @json_el2["type_of"] = "tralala"
    assert_not @report2.save_with_contents([@json_el2]), "Report with invalid json_element (invalid type_of) was saved"

    @report2 = new_valid_report
    @json_el2 = @json_el.deep_dup
    @json_el2["sort_order"] = "tralala"
    assert_not @report2.save_with_contents([@json_el2]), "Report with invalid json_element (invalid sort_order) was saved"

    @report2 = new_valid_report
    @json_el2 = @json_el.deep_dup
    @json_el2.delete("id")
    assert_not @report2.save_with_contents([@json_el2]), "Report with invalid json_element (without id) was saved"

    @report2 = new_valid_report
    @json_el2 = @json_el.deep_dup
    @json_el2["id"] = -1
    assert_not @report2.save_with_contents([@json_el2]), "Report with invalid json_element (invalid id) was saved"

    @report2 = new_valid_report
    @json_el2 = @json_el.deep_dup
    assert @report2.save_with_contents([@json_el2]), "Report with valid json_element was not saved"
  end

  private

  def new_valid_report
    Report.new(
      name: "report 2",
      project: projects(:interfaces),
      user: users(:steve)
    )
  end
end
