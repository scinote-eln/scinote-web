# frozen_string_literal: true

class FixDefault201dpiLabelTemplates < ActiveRecord::Migration[7.0]
  def up
    LabelTemplate.where(
      content: "^XA\n^MTT\n^MUD,200,200\n^PR2\n^MD30\n^LH0,8\n^PW180\n^CF0,15\n^FO0,5^FD{{ITEM_ID}}^FS\n^FO0,13^BQN,2,3^FDMA,{{ITEM_ID}}^FS\n^FO70,27^FB100,2,0,L^FD{{NAME}}^FS^FS\n^XZ\n"
    ).update!(
      content: "^XA\n^MTT\n^MUD,200,200\n^PR2\n^MD30\n^LH0,8\n^PW180\n^CF0,15\n^FO0,5^FD{{ITEM_ID}}^FS\n^FO0,13^BQN,2,3^FDMA,{{ITEM_ID}}^FS\n^FO70,27^FB100,4,0,L^FD{{NAME}}^FS^FS\n^XZ\n"
    )
  end

  def down
    LabelTemplate.where(
      content: "^XA\n^MTT\n^MUD,200,200\n^PR2\n^MD30\n^LH0,8\n^PW180\n^CF0,15\n^FO0,5^FD{{ITEM_ID}}^FS\n^FO0,13^BQN,2,3^FDMA,{{ITEM_ID}}^FS\n^FO70,27^FB100,4,0,L^FD{{NAME}}^FS^FS\n^XZ\n"
    ).update!(
      content: "^XA\n^MTT\n^MUD,200,200\n^PR2\n^MD30\n^LH0,8\n^PW180\n^CF0,15\n^FO0,5^FD{{ITEM_ID}}^FS\n^FO0,13^BQN,2,3^FDMA,{{ITEM_ID}}^FS\n^FO70,27^FB100,2,0,L^FD{{NAME}}^FS^FS\n^XZ\n"
    )
  end
end
