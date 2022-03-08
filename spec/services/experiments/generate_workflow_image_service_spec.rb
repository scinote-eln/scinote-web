# frozen_string_literal: true

require 'rails_helper'

describe Experiments::GenerateWorkflowImageService do
  let(:experiment) { create :experiment, :with_tasks }
  let(:params) { { experiment_id: experiment.id } }

  context 'when succeed' do
    it 'succeed? returns true' do
      expect(described_class.call(params).succeed?).to be_truthy
    end

    it 'worklfow image of experiment is updated' do
      old_filename = experiment.workflowimg_file_name
      described_class.call(params)
      experiment.reload

      expect(experiment.workflowimg_file_name).not_to be == old_filename
    end
  end
end
