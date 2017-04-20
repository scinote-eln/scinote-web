class AddExperimentToActivities < ActiveRecord::Migration
  def change
    add_reference :activities, :experiment, index: true, foreign_key: true
  end
end
