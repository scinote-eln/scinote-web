# frozen_string_literal: true

class LabelTemplate < ApplicationRecord
  enum language_type: { zpl: 0 }
end

class CreateLabelTemplates < ActiveRecord::Migration[6.1]
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
          ^CF0,14
          ^FO10,10^FD{{item_id}}^FS
          ^FO10,10^BY1,2.0,20^BQN,2,3^FDMA{{item_id}}^FS
          ^FO80,33^FB100,4,0,L^FD{{item_name}}^FS^FS
          ^XZ
        HEREDOC
    )
  end
end
