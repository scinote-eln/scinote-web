require 'nokogiri'
module TinyMceHelper
  def parse_tiny_mce_asset_to_token(text, ref = nil)
    html = Nokogiri::HTML(text)
    html.search('img').each do |img|
      next unless img['data-token']
      img_id = Base62.decode(img['data-token'])
      token = "[~tiny_mce_id:#{img_id}]"
      img.replace(token)
      next unless ref
      tiny_img = TinyMceAsset.find_by_id(img_id)
      tiny_img.reference = ref unless tiny_img.step || tiny_img.result_text
      tiny_img.editing = false
      tiny_img.save
    end
    html
  end

  def generate_image_tag_from_token(text, ref = nil)
    regex = /\[~tiny_mce_id:([0-9a-zA-Z]+)\]/
    new_text = text.gsub(regex) do |el|
      match = el.match(regex)
      img = TinyMceAsset.find_by_id(match[1])
      next unless img
      image_tag img.url, data: { token: Base62.encode(img.id) }
    end
  end

  def link_tiny_mce_assets(text, ref)
    regex = /\[~tiny_mce_id:([0-9a-zA-Z]+)\]/
    text.gsub(regex) do |img|
      match = img.match(regex)
      tiny_img = TinyMceAsset.find_by_id(match[1])
      next unless tiny_img
      tiny_img.public_send("#{ref.class.to_s.underscore}=".to_sym, ref)
      tiny_img.editing = false
      tiny_img.save!
    end
  end
end
