module TinyMceHelper
  def parse_tiny_mce_asset_to_token(text, obj)
    ids = []
    html = Nokogiri::HTML(remove_pasted_tokens(text))
    html.search('img').each do |img|
      next unless img['data-token']
      img_id = Base62.decode(img['data-token'])
      ids << img_id
      token = "[~tiny_mce_id:#{img_id}]"
      img.replace(token)
      next unless obj
      tiny_img = TinyMceAsset.find_by_id(img_id)
      tiny_img.reference = obj unless tiny_img.step || tiny_img.result_text
      tiny_img.save
    end
    destroy_removed_tiny_mce_assets(ids, obj) if obj
    html
  end

  # @param pdf_export_ready is needed for wicked_pdf in export report action
  def generate_image_tag_from_token(text, obj, pdf_export_ready = false)
    return unless text
    regex = Constants::TINY_MCE_ASSET_REGEX
    text.gsub(regex) do |el|
      match = el.match(regex)
      img = TinyMceAsset.find_by_id(match[1])
      next unless img && check_image_permissions(obj, img)
      if pdf_export_ready
        report_image_asset_url(img, :tiny_mce_asset, 'tiny-mce-pdf-ready')
      else
        image_tag(img.url,
                  class: 'img-responsive',
                  data: { token: Base62.encode(img.id) })
      end
    end
  end

  def link_tiny_mce_assets(text, ref)
    ids = []
    regex = Constants::TINY_MCE_ASSET_REGEX
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

  def replace_tiny_mce_assets(text, img_ids)
    img_ids.each do |src_id, dest_id|
      regex = /\[~tiny_mce_id:#{src_id}\]/
      new_token = "[~tiny_mce_id:#{dest_id}]"
      text.sub!(regex, new_token)
    end
    text
  end

  def destroy_removed_tiny_mce_assets(ids, ref)
    # need to check if the array is empty because if we pass the empty array
    # in the SQL query it will not work properly
    if ids.empty?
      ref.tiny_mce_assets.destroy_all
    else
      ref.tiny_mce_assets.where.not('id IN (?)', ids).destroy_all
    end
  end

  def check_image_permissions(obj, img)
    if obj.class == Step
      img.step == obj
    elsif obj.class == ResultText
      img.result_text == obj
    end
  end

  def remove_pasted_tokens(text)
    regex = Constants::TINY_MCE_ASSET_REGEX
    text.gsub(regex, ' ')
  end
end
