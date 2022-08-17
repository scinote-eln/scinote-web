# frozen_string_literal: true

require File.expand_path('app/helpers/database_helper')
class GenerateStepOrderableRelation < ActiveRecord::Migration[6.1]
  include DatabaseHelper

  def up
    Step.preload(:step_texts, :step_tables, :checklists).find_in_batches(batch_size: 100) do |steps|
      steps.each do |step|
        position = 0
        orderable_elements = []
        step.step_texts.each do |text|
          orderable_elements << step.step_orderable_elements.new(orderable: text, position: position)
          position += 1
        end
        step.step_tables.each do |table|
          orderable_elements << step.step_orderable_elements.new(orderable: table, position: position)
          position += 1
        end
        step.checklists.each do |checklist|
          orderable_elements << step.step_orderable_elements.new(orderable: checklist, position: position)
          position += 1
        end

        StepOrderableElement.import(orderable_elements)
      end
    end
  end

  def down
    StepOrderableElement.destroy_all
  end
end
