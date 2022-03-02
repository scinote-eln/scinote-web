# frozen_string_literal: true

require 'rails_helper'

describe 'my_modules:fix_positions' do
  include_context 'rake'

  before(:all) do
    experiment = create :experiment

    100.times do
      create :my_module, experiment: experiment, created_by: experiment.created_by
    end

    # set 10 tasks same position
    my_modules_with_same_position = MyModule.limit(10)
    my_modules_with_same_position.update_all(x: 0, y: 0)

    # 1 module should be invalid
    my_modules_with_same_position.second.update_column(:name, 'a')

    my_modules_with_same_position.third.update_column(:archived, true)
    @my_module_id = my_modules_with_same_position.fourth.id
  end

  context 'when record is valid except position' do
    it 'changes position for my_module' do
      expect { subject.invoke }.to(change { MyModule.find(@my_module_id).y })
    end
  end

  context 'when record is invalid' do
    it 'remains error on position' do
      subject.invoke
      my_module = MyModule.find_by(name: 'a')
      my_module.valid?

      expect(my_module.errors.messages[:position])
        .to(eq ['X and Y position has already been taken by another task in the experiment.'])
    end
  end
end
