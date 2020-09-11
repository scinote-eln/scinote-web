# frozen_string_literal: true

class MyModuleStatusConsequence < ApplicationRecord
  belongs_to :my_module_status

  def runs_in_background?
    false
  end
end
