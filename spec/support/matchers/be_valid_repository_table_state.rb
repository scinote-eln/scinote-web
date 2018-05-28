require 'rspec/expectations'

RSpec::Matchers.define :be_valid_repository_table_state do
  match do |subject|
    expect(subject).to be_truthy
    expect(subject).to be_an_instance_of RepositoryTableState

    state = subject.state

    expect(state).to be_an_instance_of Hash
    expect(state).to include(
      'time', 'order', 'start', 'length', 'search', 'columns', 'ColReorder'
    )

    expect(state['time']).to be_an_instance_of String
    expect { Integer(state['time']) }.to_not raise_error
    expect { Time.at(state['time'].to_i) }.to_not raise_error

    expect(state['start']).to eq "0"

    expect { Integer(state['length']) }.to_not raise_error
    cols_length = Integer(state['length'])

    # There should always be at least 6 columns
    expect(cols_length).to be >= 6

    col_indexes = []
    expect(state['columns']).to be_an_instance_of Hash
    expect(state['columns'].length).to eq cols_length
    state['columns'].each do |key, val|
      expect(key).to be_an_instance_of String
      expect { Integer(key) }.to_not raise_error

      expect(val).to be_an_instance_of Hash
      expect(val).to include(
        'search', 'visible', 'searchable'
      )
      expect(val['visible']).to eq('true').or eq('false')
      expect(val['searchable']).to eq('true').or eq('false')
      expect(val['search']).to be_an_instance_of Hash
      expect(val['search']).to include(
        'regex', 'smart', 'search', 'caseInsensitive'
      )
      expect(val['search']['regex']).to eq('true').or eq('false')
      expect(val['search']['smart']).to eq('true').or eq('false')
      expect(val['search']['caseInsensitive']).to eq('true').or eq('false')
      expect(val['search']['search']).to be_an_instance_of String

      col_indexes << Integer(key)
    end

    col_indexes.sort!

    # Check if column indexes are 0..N
    expect(col_indexes).to eq [*0..(cols_length - 1)]

    expect(state['order']).to be_an_instance_of Hash
    expect(state['order'].length).to be > 0
    state['order'].each do |key, val|
      expect(key).to be_an_instance_of String
      expect { Integer(key) }.to_not raise_error

      expect(val).to be_an_instance_of Array
      expect(val.length).to eq 2
      expect(val[0]).to be_an_instance_of String
      expect { Integer(val[0]) }.to_not raise_error
      expect(val[1]).to be_an_instance_of String
      expect(val[1]).to eq('asc').or eq('desc')

      # Check that the ordering column exists in columns
      expect(col_indexes).to include(Integer(val[0]))
    end

    expect(state['search']).to be_an_instance_of Hash
    expect(state['search']).to include(
      'regex', 'smart', 'search', 'caseInsensitive'
    )
    expect(state['search']['regex']).to eq('true').or eq('false')
    expect(state['search']['smart']).to eq('true').or eq('false')
    expect(state['search']['caseInsensitive']).to eq('true').or eq('false')
    expect(state['search']['search']).to be_an_instance_of String

    expect(state['ColReorder']).to be_an_instance_of Array
    expect(state['ColReorder'].length).to eq cols_length
    state['ColReorder'].each do |col|
      expect { Integer(col) }.to_not raise_error

      # Column should be in the columns indexes
      expect(col_indexes).to include (Integer(col))
    end
  end

  failure_message do
    'expected to be valid repository table state, but was not'
  end
end