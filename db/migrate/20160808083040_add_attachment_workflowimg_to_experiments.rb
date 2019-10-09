class AddAttachmentWorkflowimgToExperiments < ActiveRecord::Migration[4.2]
  def self.up
    add_attachment :experiments, :workflowimg
  end

  def self.down
    remove_attachment :experiments, :workflowimg
  end
end
