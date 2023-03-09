# frozen_string_literal: true

class FixLabelTemplate < ActiveRecord::Migration[6.1]
  def change
    # rubocop:disable Rails/SkipsModelValidations
    LabelTemplate.last.update_columns(
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
    # rubocop:enable Rails/SkipsModelValidations
  end
end
