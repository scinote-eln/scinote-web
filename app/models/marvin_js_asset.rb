# frozen_string_literal: true

class MarvinJsAsset < ApplicationRecord
  validates :name, presence: true
  validates :description, presence: true
  validates :object_id, presence: true
  validates :object_type, presence: true

  belongs_to :object, polymorphic: true,
                      optional: true,
                      inverse_of: :marvin_js_assets

  belongs_to :team, inverse_of: :marvin_js_assets, optional: true

  def self.add_sketch(values, team)
    if values[:object_type] == 'TinyMceAsset'
      tiny_mce_img = TinyMceAsset.create(
        object: nil,
        team_id: team.id,
        saved: false,
        image: values[:image],
        image_file_name: "#{name}.jpg"
      )
      values[:object_id] = tiny_mce_img.id
    end
    values[:name] = I18n.t('marvinjs.new_sketch') if values[:name].empty?
    create(values.merge(team_id: team.id).except(:image))
  end

  def self.update_sketch(values, team)
    sketch = team.marvin_js_assets.find(values[:id])
    return false unless sketch

    values[:name] = I18n.t('marvinjs.new_sketch') if values[:name].empty?
    sketch.update(values.except(:image, :object_type, :id))

    if values[:object_type] == 'TinyMceAsset'
      image = TinyMceAsset.find(sketch.object_id)
      image.update(image: values[:image], image_file_name: "#{name}.jpg")
      return { url: image.url(:large), description: sketch.description }
    end
    sketch
  end
end
