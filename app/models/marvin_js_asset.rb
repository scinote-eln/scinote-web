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
      # Decode the file bytes
      #image = values[:image].split(';')
      #tiny_mce_img.image = StringIO.new(
      #  Base64.decode64(image[1])
      #)
      #tiny_mce_img.image_content_type = image[0].split(':')[1]
      tiny_mce_img.save!

      values[:object_id] = tiny_mce_img.id
    end
    create(values.merge({team_id: team.id}).except(:image))
  end

end
