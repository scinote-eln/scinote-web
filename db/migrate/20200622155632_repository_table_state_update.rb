# frozen_string_literal: true

class RepositoryTableStateUpdate < ActiveRecord::Migration[6.0]
  class TempStateModel < ApplicationRecord
    self.table_name = 'repository_table_states'
  end

  def up
    TempStateModel.find_each do |table_state|
      state = table_state.state
      order_state = state['order'][0][0]
      state['order'][0][0] = order_state + 2 if order_state > 5
      2.times do
        state['columns'].insert(6,
                                'search' => {
                                  'regex' => false, 'smart' => true, 'search' => '', 'caseInsensitive' => true
                                },
                                'visible' => false)
      end
      state['ColReorder'] = state['ColReorder'].map { |i| i > 5 ? i + 2 : i } + [6, 7]
      table_state.update(state: state)
    end
  end
end

