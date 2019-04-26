class MarvinJsAsset < ApplicationRecord

  belongs_to :object, polymorphic: true,
                      optional: true,
                      inverse_of: :marvin_js_assets

  belongs_to :team, inverse_of: :marvin_js_assets, optional: true

  def self.add_sketch(values,team)
    create(values.merge({team_id: team.id}))
  end

end
