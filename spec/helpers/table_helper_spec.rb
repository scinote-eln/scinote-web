# frozen_string_literal: true

require 'rails_helper'

describe TableHelper do
  # Minimal host that mirrors the attributes TableHelper reads from a Table.
  let(:host_class) do
    Class.new do
      include TableHelper

      attr_reader :contents, :metadata

      def initialize(contents:, metadata: {}, well_plate: false)
        @contents = contents
        @metadata = metadata
        @well_plate = well_plate
      end

      def well_plate?
        @well_plate
      end
    end
  end

  let(:contents) { { data: [[1, 2], [3, 4]] }.to_json }

  def build_host(**options)
    host_class.new(contents: options.delete(:contents) || contents, **options)
  end

  describe '#table_data' do
    it 'returns sizes and titles for a table with letter column titles' do
      content = build_host.table_data

      expect(content[:contents]).to eq [[1, 2], [3, 4]]
      expect(content[:rows_size]).to eq [27, 27]
      expect(content[:columns_size]).to eq [100, 100]
      expect(content[:rows_title]).to eq [1, 2]
      expect(content[:columns_title]).to eq %w[A B]
      expect(content[:cells_attributes]).to eq({})
    end

    it 'uses letter row titles and numeric column titles for well plates' do
      content = build_host(well_plate: true).table_data

      expect(content[:rows_title]).to eq %w[A B]
      expect(content[:columns_title]).to eq [1, 2]
    end

    it 'replaces cell values with their calculated results' do
      metadata = { 'cells' => [{ 'row' => 0, 'col' => 1, 'calculated' => 42 }] }

      content = build_host(metadata: metadata).table_data

      expect(content[:contents]).to eq [[1, 42], [3, 4]]
    end

    it 'supports the legacy hash format of cells' do
      metadata = { 'cells' => { 'a' => { 'row' => 1, 'col' => 0, 'calculated' => 'x' } } }

      content = build_host(metadata: metadata).table_data

      expect(content[:contents]).to eq [[1, 2], ['x', 4]]
    end

    it 'ignores cells without a calculated value' do
      metadata = { 'cells' => [{ 'row' => 0, 'col' => 0, 'calculated' => nil }] }

      expect(build_host(metadata: metadata).table_data[:contents]).to eq [[1, 2], [3, 4]]
    end

    it 'returns an empty hash when there is no data' do
      expect(build_host(contents: { data: [] }.to_json).table_data).to eq({})
    end
  end

  describe '#convert_index_to_letter' do
    it 'maps single letters for the first 26 indexes' do
      host = build_host
      expect(host.convert_index_to_letter(0)).to eq 'A'
      expect(host.convert_index_to_letter(25)).to eq 'Z'
    end

    it 'continues with two and three letter names' do
      host = build_host
      expect(host.convert_index_to_letter(26)).to eq 'AA'
      expect(host.convert_index_to_letter(27)).to eq 'AB'
      expect(host.convert_index_to_letter(701)).to eq 'ZZ'
      expect(host.convert_index_to_letter(702)).to eq 'AAA'
    end
  end
end
