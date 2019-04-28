class MarvinJsAsset < ApplicationRecord

  belongs_to :object, polymorphic: true,
                      optional: true,
                      inverse_of: :marvin_js_assets

  belongs_to :team, inverse_of: :marvin_js_assets, optional: true

  def self.add_sketch(values,team)
    if values[:object_type] == 'TinyMceAsset'
      tiny_mce_img = TinyMceAsset.new(
        object: nil,
        team_id: team.id,
        saved: false,
        image: values[:image],
        image_file_name: "#{name}.jpg"
      )
      tiny_mce_img.save!

      values[:object_id] = tiny_mce_img.id
    end
    create(values.merge({team_id: team.id}).except(:image))
  end

  def self.update_sketch(values)
    sketch=MarvinJsAsset.find(values[:id])
    sketch.update(values.except(:image,:object_type,:id))
    if values[:object_type] == 'TinyMceAsset'
      image = TinyMceAsset.find(sketch.object_id)
      image.update(image: values[:image])
      return {url: image.url(:large)}
    end
    return sketch
  end

end
