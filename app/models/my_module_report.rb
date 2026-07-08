# frozen_string_literal: true

class MyModuleReport < ApplicationRecord
  belongs_to :my_module

  has_one_attached :report
end
