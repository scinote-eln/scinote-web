# frozen_string_literal: true

class MyModuleStatusConsequence < ApplicationRecord
  belongs_to :my_module_status

  def forward(my_module); end

  def backward(my_module); end

  def before_forward_call(my_module, user = nil); end

  def runs_in_background?
    false
  end
end
