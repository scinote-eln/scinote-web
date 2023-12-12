require 'rspec/expectations'

RSpec::Matchers.define :be_valid_default_repository_table_state do |nr_of_cols|
  match do |subject|
    expect(subject).to be_truthy
    expect(subject).to be_an_instance_of RepositoryTableState

    state = subject.state

    cols_length = 9 + nr_of_cols
    cols_array = [*0..(8 + nr_of_cols)]

    expect(state).to be_an_instance_of Hash
    expect(state).to include(
      'time',
      'columns',
      'start' => 0,
      'length' => 10,
      'order' => [[3, 'asc']],
      'assigned' => 'assigned',
      'ColReorder' => cols_array
    )

    expect(state['columns']).to be_an_instance_of Array
    expect(state['columns'].length).to eq(cols_length)
    state['columns'].each_with_index do |val, i|
      expect(val).to include(
        'visible' => !([4, 7, 8].include? i),
        'searchable' => (![0, 4].include?(i)),
        'search' => {
          'search' => '', 'smart' => true, 'regex' => false, 'caseInsensitive' => true
        }
      )
    end

    expect { Time.at(state['time'].to_i) }.to_not raise_error
  end

  failure_message do
    'expected to be valid default repository table state, but was not'
  end
end
