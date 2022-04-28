# frozen_string_literal: true

class CreateLabelTemplates < ActiveRecord::Migration[6.1]
  class LabelTemplate < ApplicationRecord
    enum language_type: { zpl: 0 }
  end

  def change
    create_table :label_templates do |t|
      t.string :name, null: false
      t.text :content, null: false
      t.integer :language_type, index: true
      t.boolean :default, default: false, null: false
      t.string :size

      t.timestamps
    end

    LabelTemplate.create(
      name: 'SciNote Item',
      size: '1" x 0.5" / 25.4mm x 12.7mm',
      language_type: :zpl,
      default: true,
      content:
        <<~HEREDOC
          ^XA
          ^MTT
          ^MUD,300,300
          ^PR2
          ^MD30
          ^LH20,20
          ^PW310
          ^CF0,23
          ^FO0,0^FD{{item_id}}^FS
          ^FO0,20^BQN,2,4^FDMA,{{item_id}}^FS
          ^FO95,30^FB180,4,0,L^FD{{item_name}}^FS^FS
          ^XZ
        HEREDOC
    )
  end
end
