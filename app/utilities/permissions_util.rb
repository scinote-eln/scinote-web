module PermissionsUtil
  def self.get_comment_module(comment)
    comment = comment.becomes(comment.type.constantize)
    my_module = case comment
                when TaskComment
                  comment.my_module
                when ResultComment
                  comment.result.my_module
                when StepComment
                  comment.step.protocol.my_module
                end
    my_module
  end

  def self.reference_project(obj)
    return obj.experiment.project if obj.is_a? MyModule
    return obj.project if obj.is_a? Experiment
    obj
  end
end
