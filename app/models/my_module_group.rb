class MyModuleGroup < ApplicationRecord
  include SearchableModel

  validates :experiment, presence: true

  belongs_to :experiment, inverse_of: :my_module_groups, optional: true
  belongs_to :created_by,
             foreign_key: 'created_by_id',
             class_name: 'User',
             optional: true
  has_many :my_modules, inverse_of: :my_module_group, dependent: :nullify

  def ordered_modules
    my_modules.order(workflow_order: :asc)
  end

  def deep_clone_to_experiment(current_user, experiment)
    clone = MyModuleGroup.new(
      created_by: created_by,
      experiment: experiment
    )

    # Get clones of modules from this group, save them as hash
    cloned_modules = ordered_modules.each_with_object({}) do |m, hash|
      hash[m.id] = m.deep_clone_to_experiment(current_user, experiment)
      hash
    end

    ordered_modules.each do |m|
      # Copy connections
      m.inputs.each do |inp|
        Connection.create(
          input_id: cloned_modules[inp[:input_id]].id,
          output_id: cloned_modules[inp[:output_id]].id
        )
      end

      # Copy remaining variables
      cloned_module = cloned_modules[m.id]
      cloned_module.my_module_group = self
      cloned_module.created_by = m.created_by
      cloned_module.workflow_order = m.workflow_order
    end

    clone.my_modules << cloned_modules.values
    clone.save
    clone
  end
end
