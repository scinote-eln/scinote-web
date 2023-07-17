# frozen_string_literal: true

module Service
  def call(*args, **kwargs)
    new(*args, **kwargs).call
  end
end
