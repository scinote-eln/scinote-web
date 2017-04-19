class StepTinyMceAsset < ActiveRecord::Base
  belongs_to :step
  belongs_to :asset
end
