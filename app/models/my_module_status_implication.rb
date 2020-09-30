# frozen_string_literal: true

class MyModuleStatusImplication < ApplicationRecord
  belongs_to :my_module_status

  def description
    ''
  end
end
