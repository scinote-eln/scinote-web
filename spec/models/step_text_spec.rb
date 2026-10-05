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
end
