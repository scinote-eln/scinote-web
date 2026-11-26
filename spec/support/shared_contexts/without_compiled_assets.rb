# frozen_string_literal: true

# CI neither compiles app/assets/builds (gitignored) nor installs node_modules, so a layout or a template that calls
# stylesheet_link_tag / javascript_include_tag / asset_path raises there (Sprockets::Rails::Helper::AssetNotFound for
# a missing build, Sprockets::FileNotFound when Sprockets tries to compile a pack that requires an npm package),
# while the same example passes on a machine that has the assets built. Use this context in examples that use
# `render_views`: the templates still render for real, but asset helpers only look at the (empty) manifest and fall
# back to a plain /assets/<name> url instead of compiling or raising.
#
# Templates that read the compiled files themselves (Rails.application.assets_manifest.find_sources) are not
# covered by this; stub those in the example that needs them.
RSpec.shared_context 'without compiled assets' do
  around do |example|
    previous = {
      unknown_asset_fallback: ActionView::Base.unknown_asset_fallback,
      resolve_assets_with: ActionView::Base.resolve_assets_with
    }
    ActionView::Base.unknown_asset_fallback = true
    ActionView::Base.resolve_assets_with = [:manifest]
    example.run
  ensure
    previous.each { |name, value| ActionView::Base.public_send("#{name}=", value) }
  end
end
