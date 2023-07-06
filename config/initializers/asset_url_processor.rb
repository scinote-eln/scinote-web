class AssetUrlProcessor
  def self.call(input)
    context = input[:environment].context_class.new(input)
    data = input[:data].gsub(/(\w*)-url\(\s*["']?(?!(?:\#|data|http))([^"'\s)]+)\s*["']?\)/) do |_match|
      "url(#{context.asset_path($2, type: $1)})"
    end
    {data: data}
  end
end

Sprockets.register_postprocessor "text/css", AssetUrlProcessor
