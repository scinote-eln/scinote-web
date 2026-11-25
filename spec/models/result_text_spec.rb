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

  describe '#text_digest' do
    let!(:result_text) { create :result_text, text: 'Original text', result: create(:result) }

    it 'is the SHA256 hex digest of the text' do
      expect(result_text.text_digest).to eq(Digest::SHA256.hexdigest('Original text'))
    end

    it 'changes when the text changes' do
      expect { result_text.update!(text: 'Updated text') }
        .to change(result_text, :text_digest).to(Digest::SHA256.hexdigest('Updated text'))
    end

    it 'is the digest of an empty string when the text is nil' do
      expect(build(:result_text, text: nil).text_digest).to eq(Digest::SHA256.hexdigest(''))
    end

    it 'stays the digest of the stored text after rendering rewrote a legacy image token in memory' do
      legacy_text = 'Legacy [~tiny_mce_id:999999999] text'
      result_text.update_column(:text, legacy_text)
      result_text.reload.tinymce_render('text')

      expect(result_text.text_digest).to eq(Digest::SHA256.hexdigest(legacy_text))
    end
  end
end
