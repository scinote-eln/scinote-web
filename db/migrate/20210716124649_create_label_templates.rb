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
          ^CF0,21
          ^FO10,0^FD{{item_id}}^FS
          ^FO5,3^BY3,3.0,25^BQN,2,4^FDMA\\{{item_id}}^FS
          ^FO100,39^FB190,20,5,L^FD{{item_name}}^FS^FS
          ^XZ
        HEREDOC
    )
  end
end
