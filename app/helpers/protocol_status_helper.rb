module ProtocolStatusHelper

  def protocol_name(protocol)
    if protocol_private_for_current_user?(protocol)
      I18n.t('my_modules.protocols.protocol_status_bar.private_parent')
    else
      escape_input(protocol.name)
    end
  end

  private

  def protocol_private_for_current_user?(protocol)
    protocol.in_repository_private? && protocol.added_by != current_user
  end
end
