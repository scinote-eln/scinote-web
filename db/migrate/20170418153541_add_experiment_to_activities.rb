class AddExperimentToActivities < ActiveRecord::Migration[4.2]
  def change
    add_reference :activities, :experiment, index: true, foreign_key: true
  end
end
