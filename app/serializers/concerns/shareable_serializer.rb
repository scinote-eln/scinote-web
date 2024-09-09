# frozen_string_literal: true

module ShareableSerializer
  extend ActiveSupport::Concern

  included do
    attributes :shared, :shared_label, :ishared, :shared_read, :shared_write, :shareable_write
  end

  def shared
    object.shared_with?(current_user.current_team)
  end

  def shared_label
    case object[:shared]
    when 1
      I18n.t('libraries.index.shared')
    when 2
      I18n.t('libraries.index.shared_for_editing')
    when 3
      I18n.t('libraries.index.shared_for_viewing')
    when 4
      I18n.t('libraries.index.not_shared')
    end
  end

  def ishared
    object.i_shared?(current_user.current_team)
  end

  def shared_read
    object.shared_read?
  end

  def shared_write
    object.shared_write?
  end

  def shareable_write
    object.shareable_write?
  end
end
