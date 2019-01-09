# frozen_string_literal: true

require 'rails_helper'

describe WorkflowImageGenerator do
  let(:experiment) { create :experiment_with_tasks }
  let(:params) { { experiment_id: experiment.id } }

  context 'when succeed' do
    it 'succeed? returns true' do
      expect(described_class.execute(params).succeed?).to be_truthy
    end

    it 'worklfow image of experiment is updated' do
      old_filename = experiment.workflowimg_file_name
      described_class.execute(params)
      experiment.reload

      expect(experiment.workflowimg_file_name).not_to be == old_filename
    end
  end
end
