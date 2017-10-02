module TinyMceHelper
  def parse_tiny_mce_asset_to_token(text, obj)
    ids = []
    html = Nokogiri::HTML(text)
    html.search('img').each do |img|
      next unless img['data-token']
      img_id = Base62.decode(img['data-token'])
      ids << img_id
      token = "[~tiny_mce_id:#{img_id}]"
      img.replace(token)
      next unless obj
      tiny_img = TinyMceAsset.find_by_id(img_id)
      next if check_parse_token_permissions(obj, tiny_img)
      tiny_img.reference = obj unless tiny_img.step || tiny_img.result_text
      tiny_img.save
    end
    destroy_removed_tiny_mce_assets(ids, obj) if obj
    html
  end

  def generate_image_tag_from_token(text, obj)
    return unless text
    regex = /\[~tiny_mce_id:([0-9a-zA-Z]+)\]/
    text.gsub(regex) do |el|
      match = el.match(regex)
      img = TinyMceAsset.find_by_id(match[1])
      next unless img && img.team == current_team
      next unless check_image_permissions(obj, img)
      image_tag img.url,
                class: 'img-responsive',
                data: { token: Base62.encode(img.id) }
    end
  end

  def link_tiny_mce_assets(text, ref)
    ids = []
    regex = /\[~tiny_mce_id:([0-9a-zA-Z]+)\]/
    text.gsub(regex) do |img|
      match = img.match(regex)
      tiny_img = TinyMceAsset.find_by_id(match[1])
      next unless tiny_img
      ids << tiny_img.id
      tiny_img.public_send("#{ref.class.to_s.underscore}=".to_sym, ref)
      tiny_img.save!
    end
    destroy_removed_tiny_mce_assets(ids, ref)
  end

  def destroy_removed_tiny_mce_assets(ids, ref)
    ref.tiny_mce_assets.where.not('id IN (?)', ids).destroy_all
  end

  def check_image_permissions(obj, img)
    if obj.class == Step
      return img.step == obj
    elsif obj.class == ResultText
      return img.result_text == obj
    end
  end

  def check_parse_token_permissions(obj, img)
    return true if obj.class == Step && img.result_text.nil?
    return true if obj.class == ResultText && img.step.nil?
  end
end
