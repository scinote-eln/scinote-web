# frozen_string_literal: true

require 'rails_helper'

describe ResultText, type: :model do
  let(:result_text) { build :result_text, result: create(:result) }

  it 'is valid' do
    expect(result_text).to be_valid
  end

  it 'should be of class ResultText' do
    expect(subject.class).to eq ResultText
  end

  describe 'Database table' do
    it { should have_db_column :result_id }
    it { should have_db_column :text }
  end

  describe 'Relations' do
    it { should belong_to(:result) }
    it { should have_many :tiny_mce_assets }
  end

  describe 'Validations' do
    describe '#text' do
      it { is_expected.to validate_length_of(:text).is_at_most(Constants::RICH_TEXT_MAX_LENGTH) }
    end
  end

  describe 'content update broadcasting' do
    let!(:result_text) { create :result_text, result: create(:result) }

    it 'broadcasts content_updated to the subject stream when the text changes' do
      expect { result_text.update!(text: 'Updated text') }
        .to have_broadcasted_to(result_text)
        .from_channel(EditingFlagsChannel)
        .with(hash_including('action' => 'content_updated', 'subject_type' => 'ResultText', 'subject_id' => result_text.id))
    end

    it 'broadcasts content_updated to the subject stream when the name changes' do
      expect { result_text.update!(name: 'Updated name') }
        .to have_broadcasted_to(result_text)
        .from_channel(EditingFlagsChannel)
        .with(hash_including('action' => 'content_updated'))
    end

    it 'does not broadcast when an unrelated attribute changes' do
      expect { result_text.update!(locked: true) }
        .not_to have_broadcasted_to(result_text).from_channel(EditingFlagsChannel)
    end
  end
end
