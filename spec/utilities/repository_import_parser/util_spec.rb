# frozen_string_literal: true

require 'rails_helper'

describe RepositoryImportParser::Util do
  describe '.split_by_delimiter' do
    let(:text) { "one two\nwithth\tree\nfour" }
    let(:delimiter) { ' ' }
    let(:split_by_delimiter) { RepositoryImportParser::Util.split_by_delimiter(text: text, delimiter: delimiter) }

    context 'when delimiter is white space' do
      it 'returns array with 2 items' do
        expect(split_by_delimiter.count).to eq 2
      end

      context 'when has more whitespaces' do
        let(:text) { " mo\tre than just   a one withe\nspace " }
        it 'returns array with 6 items' do
          expect(split_by_delimiter.count).to eq 6
        end
      end
    end

    context 'when delimiter is new line' do
      let(:delimiter) { "\n" }
      it 'returns array with 3 items' do
        expect(split_by_delimiter.count).to eq 3
      end
    end

    context 'when delimiter is comma' do
      let(:delimiter) { ',' }
      it 'returns array with 1 item' do
        expect(split_by_delimiter.count).to eq 1
      end
    end
  end
end
