# frozen_string_literal: true

module ShareableSerializer
  extend ActiveSupport::Concern

  included do
    attributes :shared, :shared_label, :ishared, :shared_read, :shared_write, :shareable_write, :current_team
  end

  def current_team
    current_user.current_team.name
  end

  def shared
    shared_object.shared_with?(current_user.current_team)
  end

  def shared_label
    case shared_object[:shared]
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
    shared_object.i_shared?(current_user.current_team)
  end

  def shared_read
    shared_object.shared_read?
  end

  def shared_write
    shared_object.shared_write?
  end

  def shareable_write
    shared_object.shareable_write?
  end

  private

  def shared_object
    instance_options[:shared_object] || object
  end
end
