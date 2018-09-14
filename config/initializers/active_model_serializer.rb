# frozen_string_literal: true

require 'active_model_serializers/register_jsonapi_renderer'

ActiveModelSerializers.config.adapter = :json_api
ActiveModelSerializers.config.key_transform = :unaltered
