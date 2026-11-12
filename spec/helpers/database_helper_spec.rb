# frozen_string_literal: true

require 'rails_helper'

describe DatabaseHelper, type: :helper do
  let(:connection) { ActiveRecord::Base.connection }

  def index_definition(name)
    connection.select_value("SELECT indexdef FROM pg_indexes WHERE indexname = '#{name}'")
  end

  describe '#db_adapter_is?' do
    it 'returns true for the adapter that is in use' do
      expect(helper.db_adapter_is?('PostgreSQL')).to be true
    end

    it 'returns false for another adapter name' do
      expect(helper.db_adapter_is?('SQLite')).to be false
    end
  end

  describe 'index helpers' do
    before do
      connection.execute('CREATE TABLE tmp_database_helper_specs (name text, code integer)')
    end

    after do
      connection.execute('DROP TABLE IF EXISTS tmp_database_helper_specs')
    end

    it 'creates a gist trigram index on the column' do
      helper.add_gist_index('tmp_database_helper_specs', 'name')

      expect(index_definition('index_tmp_database_helper_specs_on_name')).to include 'USING gist'
    end

    it 'creates a gin trigram index on the column with html tags trimmed' do
      helper.add_gin_index_without_tags('tmp_database_helper_specs', 'name')

      expect(index_definition('index_tmp_database_helper_specs_on_name'))
        .to include 'USING gin', 'trim_html_tags'
    end

    it 'creates and removes a gin trigram index on the text form of a number column' do
      helper.add_gin_index_for_numbers('tmp_database_helper_specs', 'code')
      expect(index_definition('index_tmp_database_helper_specs_on_code_text')).to include '(code)::text'

      helper.remove_gin_index_for_numbers('tmp_database_helper_specs', 'code')
      expect(index_definition('index_tmp_database_helper_specs_on_code_text')).to be_nil
    end

    it 'does not fail when removing an index that does not exist' do
      expect { helper.remove_gin_index_for_numbers('tmp_database_helper_specs', 'missing') }.not_to raise_error
    end
  end

  describe '#get_table_size' do
    it 'returns the size of the table in bytes' do
      size = helper.get_table_size('teams')

      expect(size).to be_a Integer
      expect(size).to be > 0
    end
  end

  describe 'octet length helpers' do
    let(:team) { create(:team, name: 'Été') }

    it 'returns the octet length of a column for a table id' do
      expect(helper.get_octet_length('teams', 'name', team.id)).to eq 'Été'.bytesize
    end

    it 'returns the octet length of a column for a record' do
      expect(helper.get_octet_length_record(team, 'name')).to eq 5
    end
  end
end
