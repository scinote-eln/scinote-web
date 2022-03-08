class Connection < ApplicationRecord
  belongs_to :to,
             class_name: 'MyModule',
             foreign_key: 'input_id',
             inverse_of: :inputs,
             optional: true
  belongs_to :from,
             class_name: 'MyModule',
             foreign_key: 'output_id',
             inverse_of: :outputs,
             optional: true
end
