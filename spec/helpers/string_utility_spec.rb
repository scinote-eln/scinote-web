# frozen_string_literal: true

require 'rails_helper'

describe StringUtility, type: :helper do
  describe '#ellipsize' do
    it 'returns the string unchanged when it is shorter than the minimum length' do
      expect(helper.ellipsize('short name', 50, 4)).to eq 'short name'
    end

    it 'returns the string unchanged when it is not longer than both edges together' do
      string = 'a' * 20

      expect(helper.ellipsize(string, 5, 10)).to eq string
    end

    it 'keeps the edges and replaces the middle with an ellipsis' do
      string = "ABCD#{'x' * 20}WXYZ"

      expect(helper.ellipsize(string, 10, 4)).to eq 'ABCD...WXYZ'
    end

    it 'uses the default minimum length and edge length from the constants' do
      string = "#{'a' * Constants::MAX_EDGE_LENGTH}#{'b' * (Constants::MAX_NAME_TRUNCATION + 1 - (2 * Constants::MAX_EDGE_LENGTH))}#{'c' * Constants::MAX_EDGE_LENGTH}"

      result = helper.ellipsize(string)

      expect(result).to eq "#{'a' * Constants::MAX_EDGE_LENGTH}...#{'c' * Constants::MAX_EDGE_LENGTH}"
    end
  end

  describe '#to_filesystem_name' do
    it 'replaces the parent directory reference with a double underscore' do
      expect(helper.to_filesystem_name('..')).to eq '__'
    end

    it 'replaces the current directory reference with an underscore' do
      expect(helper.to_filesystem_name('.')).to eq '_'
    end

    it 'replaces reserved characters with underscores' do
      expect(helper.to_filesystem_name('a/b:c*d?e')).to eq 'a_b_c_d_e'
    end

    it 'removes control characters' do
      expect(helper.to_filesystem_name("ab\u0007cd")).to eq 'abcd'
    end

    it 'replaces a leading hyphen with an underscore' do
      expect(helper.to_filesystem_name('-file')).to eq '_file'
    end

    it 'replaces trailing dots and trailing spaces' do
      expect(helper.to_filesystem_name('report...')).to eq 'report_'
      expect(helper.to_filesystem_name('name ')).to eq 'name_'
    end

    it 'truncates the name to the exported filename length' do
      result = helper.to_filesystem_name('a' * (Constants::EXPORTED_FILENAME_TRUNCATION_LENGTH + 10))

      expect(result).to eq 'a' * Constants::EXPORTED_FILENAME_TRUNCATION_LENGTH
    end

    it 'keeps non ascii letters' do
      expect(helper.to_filesystem_name('Zažene')).to eq 'Zažene'
    end
  end
end
