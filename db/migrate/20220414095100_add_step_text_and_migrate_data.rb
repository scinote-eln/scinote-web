# frozen_string_literal: true

require File.expand_path('app/helpers/database_helper')

class AddStepTextAndMigrateData < ActiveRecord::Migration[6.1]
  include DatabaseHelper

  def up
    create_table :step_texts do |t|
      t.references :step, null: false, index: true, foreign_key: true
      t.string :text

      t.timestamps
    end

    add_gin_index_without_tags :step_texts, :text

    Step.where.not(description: nil).find_in_batches(batch_size: 100) do |steps|
      step_texts = []

      steps.each do |step|
        step_texts << step.step_texts.new(text: step.description)
      end
      StepText.import(step_texts, validate: false)
    end

    Step.joins(:tiny_mce_assets, :step_texts)
        .preload(:tiny_mce_assets, :step_texts).find_each do |step|
      step_text_id = step.step_texts.take.id
      step.tiny_mce_assets.update_all(object_type: 'StepText', object_id: step_text_id)
    end
  end

  def down
    StepText.joins(:tiny_mce_assets)
            .preload(:step, :tiny_mce_assets).find_each do |step_text|
      step_text.tiny_mce_assets.update_all(object_type: 'Step', object_id: step_text.step.id)
    end

    drop_table :step_texts
  end
end
