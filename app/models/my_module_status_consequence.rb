# frozen_string_literal: true

class MyModuleStatusConsequence < ApplicationRecord
  belongs_to :my_module_status

  def runs_in_background?
    false
  end

  def forward_execution
    true
  end

  def backward_execution
    true
  end
end
