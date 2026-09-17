# frozen_string_literal: true

module RendersFlattenedElement
  extend ActiveSupport::Concern

  def render_element(serializer_class, object, **opts)
    render json: { data: { attributes: serializer_class.new(object, scope: { user: current_user }, **opts).as_json } }
  end
end
