class MakePositionOptionalForResultOrderableElement < ActiveRecord::Migration[7.2]
  def change
    change_column_null :result_orderable_elements, :position, true
  end
end
