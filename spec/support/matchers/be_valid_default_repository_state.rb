require 'rspec/expectations'

RSpec::Matchers.define :be_valid_default_repository_table_state do |nr_of_cols|
  match do |subject|
    expect(subject).to be_truthy
    expect(subject).to be_an_instance_of RepositoryTableState

    state = subject.state

    cols_length = 6 + nr_of_cols
    cols_str_array = [*0..(5 + nr_of_cols)].collect(&:to_s)

    expect(state).to be_an_instance_of Hash
    expect(state).to include(
      'time',
      'columns',
      'start' => '0',
      'length' => cols_length.to_s, # 6 default columns + parameter
      'order' => { '0'=> ['2', 'asc'] },
      'search' => {
        'search' => '',
        'smart' => 'true',
        'regex' => 'false',
        'caseInsensitive' => 'true'
      },
      'ColReorder' => cols_str_array
    )

    expect(state['columns']).to be_an_instance_of Hash
    expect(state['columns'].length).to eq (6 + nr_of_cols)
    expect(state['columns'].keys.sort).to eq cols_str_array
    state['columns'].each do |key, val|
      expect(val).to include(
        'visible' => 'true',
        'searchable' => (key == '0' ? 'false' : 'true'),
        'search' => {
          'search' => '', 'smart' => 'true', 'regex' => 'false', 'caseInsensitive' => 'true'
        }
      )
    end

    expect(state['time']).to be_an_instance_of String
    expect { Integer(state['time']) }.to_not raise_error
    expect { Time.at(state['time'].to_i) }.to_not raise_error
  end

  failure_message do
    'expected to be valid default repository table state, but was not'
  end
end