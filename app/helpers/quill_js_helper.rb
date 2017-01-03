module QuillJsHelper
  def sanitize_quill_js_input(input)
    require "#{Rails.root}/app/utilities/scrubbers/quill_js_scrubber"

    # We need to disable formatting to prevent unwanted \n
    # symbols from creeping into sanitized HTML (which
    # cause unwanted new lines when rendered in Quill.js)
    disable_formatting =
      Nokogiri::XML::Node::SaveOptions::DEFAULT_HTML ^
      Nokogiri::XML::Node::SaveOptions::FORMAT

    Loofah
      .fragment(input)
      .scrub!(QuillJsScrubber.new)
      .to_html(save_with: disable_formatting)
  end
end
