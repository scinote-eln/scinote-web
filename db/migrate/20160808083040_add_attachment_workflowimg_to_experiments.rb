class AddAttachmentWorkflowimgToExperiments < ActiveRecord::Migration
  def self.up
    change_table :experiments do |t|
      t.attachment :workflowimg
    end
  end

  def self.down
    remove_attachment :experiments, :workflowimg
  end
end
