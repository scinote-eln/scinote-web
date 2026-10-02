# frozen_string_literal: true

require 'rails_helper'

describe StepText, type: :model do
  let!(:step_text) { create :step_text, text: 'Original text', name: 'Original name' }

  describe 'content update broadcasting' do
    it 'broadcasts content_updated to the subject stream when the text changes' do
      expect { step_text.update!(text: 'Updated text') }
        .to have_broadcasted_to(step_text)
        .from_channel(EditingFlagsChannel)
        .with(hash_including('action' => 'content_updated', 'subject_type' => 'StepText', 'subject_id' => step_text.id))
    end

    it 'broadcasts content_updated to the subject stream when the name changes' do
      expect { step_text.update!(name: 'Updated name') }
        .to have_broadcasted_to(step_text)
        .from_channel(EditingFlagsChannel)
        .with(hash_including('action' => 'content_updated'))
    end

    it 'does not broadcast when an unrelated attribute changes' do
      expect { step_text.update!(locked: true) }
        .not_to have_broadcasted_to(step_text).from_channel(EditingFlagsChannel)
    end
  end

  describe '#text_digest' do
    it 'is the SHA256 hex digest of the text' do
      expect(step_text.text_digest).to eq(Digest::SHA256.hexdigest('Original text'))
    end

    it 'changes when the text changes' do
      expect { step_text.update!(text: 'Updated text') }
        .to change(step_text, :text_digest).to(Digest::SHA256.hexdigest('Updated text'))
    end

    it 'is the digest of an empty string when the text is nil' do
      expect(build(:step_text, text: nil).text_digest).to eq(Digest::SHA256.hexdigest(''))
    end

    it 'stays the digest of the stored text after rendering rewrote a legacy image token in memory' do
      legacy_text = 'Legacy [~tiny_mce_id:999999999] text'
      step_text.update_column(:text, legacy_text)
      step_text.reload.tinymce_render('text')

      expect(step_text.text_digest).to eq(Digest::SHA256.hexdigest(legacy_text))
    end
  end
end
