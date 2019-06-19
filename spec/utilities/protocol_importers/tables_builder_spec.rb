# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProtocolImporters::TablesBuilder do
  # rubocop:disable Metrics/LineLength
  let(:description_string) { '<table><tr><td>1</td><td>2</td><td>3</td><td>4</td><td>5</td><td>6</td><td>7</td><td>8</td><td>9</td><td>10</td></tr><tr><td>a</td><td>b</td><td>c</td><td>d</td><td>e</td><td>f</td><td>g</td><td>h</td><td>a</td><td>a</td></tr><tr><td>1</td><td>1</td><td>1</td><td>2</td><td>3</td><td>4</td><td>5</td><td>1</td><td>1</td><td>1</td></tr><tr><td>1</td><td>1</td><td>1</td><td>1</td><td>1</td><td>1</td><td>1</td><td>1</td><td>1</td><td>1</td></tr><tr><td>asd</td><td>as</td><td>das</td><td>a</td><td>as</td><td>asd</td><td>sad</td><td>sa</td><td>asd</td><td>as124521</td></tr></table><table><tr><td>1</td><td>2</td><td>3</td></tr></table>' }
  let(:description_string_with_headers) { '<table><tr><td></td><td>1</td><td>2</td><td>3</td></tr><tr><td>A</td><td>d1</td><td>d2</td><td>d3</td></tr><tr><td>B</td><td>c1</td><td>c2</td><td>c3</td></tr></table>' }
  # rubocop:enable Metrics/LineLength

  let(:extract_tables_from_string_result) { described_class.extract_tables_from_html_string(description_string) }
  let(:first_table_in_result) { extract_tables_from_string_result.first }

  describe '.extract_tables_from_string' do
    it 'returns array of Table instances' do
      expect(first_table_in_result).to be_instance_of(Table)
    end

    it 'returns 2 tables ' do
      expect(extract_tables_from_string_result.count).to be == 2
    end

    it 'returns valid table' do
      expect(first_table_in_result).to be_valid
    end

    it 'returns table with 5 rows' do
      expect(JSON.parse(first_table_in_result.contents)['data'].count).to be == 5
    end

    it 'returns table with 10 columns' do
      expect(JSON.parse(first_table_in_result.contents)['data'].first.count).to be == 10
    end

    context 'when droping headers' do
      it 'returns table with 2 rows and 3 columns' do
        table = described_class.extract_tables_from_html_string(description_string_with_headers, true).first

        expect(JSON.parse(table.contents)['data'].count).to be == 2
        expect(JSON.parse(table.contents)['data'].first.count).to be == 3
      end
    end
  end

  describe '.remove_tables_from_html' do
    it 'returns description string without tables' do
      expect(described_class.remove_tables_from_html(description_string)
               .scan('<p><i>There was a table here, it was moved to tables section.</i></p>').size).to eq(2)
    end
  end
end
