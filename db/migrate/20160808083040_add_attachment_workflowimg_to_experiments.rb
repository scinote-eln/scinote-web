class AddAttachmentWorkflowimgToExperiments < ActiveRecord::Migration
  def self.up
    add_attachment :experiments, :workflowimg
  end

  def self.down
    remove_attachment :experiments, :workflowimg
  end
end
