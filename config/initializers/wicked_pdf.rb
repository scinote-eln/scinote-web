WickedPdf.config ||= {}


# WickedPdfHelper patch that fixes issue with including application.css
# in environments like Heroku where assets.compile option is disabled and
# it is not acceptable to enable it.
if Rails.env.production? and Rails.configuration.assets.compile == false

  WickedPdf::WickedPdfHelper::Assets.module_eval do

    def read_asset(source)
       manifest = Rails.application.assets_manifest
       path = File.join(manifest.dir, manifest.assets[source])
       File.read(path)
    end

    def asset_exists?(source)
       Rails.application.assets_manifest.assets.key?(source)
    end
  end
end
