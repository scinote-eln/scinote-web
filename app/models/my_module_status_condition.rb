# frozen_string_literal: true

class MyModuleStatusCondition < ApplicationRecord
  belongs_to :my_module_status

  def description
    ''
  end
end
