# frozen_string_literal: true

module Users
  class InitialsAvatarService
    extend Service

    STYLE_SIZES = { icon_small: 24, icon: 40, thumb: 100, medium: 300 }.freeze
    DARK_TEXT_COLOR = '#1D2939'
    LIGHT_TEXT_COLOR = '#FFFFFF'
    FONT_FAMILY = "Inter, 'Inter var', -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif"

    def initialize(user, style = :icon_small)
      @user = user
      @size = STYLE_SIZES[style] || STYLE_SIZES[:icon_small]
    end

    def call
      initials = ERB::Util.html_escape(@user.initials[0, 2])

      [
        %(<svg xmlns="http://www.w3.org/2000/svg" width="#{@size}" height="#{@size}" viewBox="0 0 24 24">),
        %(<circle cx="12" cy="12" r="12" fill="#{@user.avatar_color}"/>),
        %(<text x="12" y="12" dy="0.35em" text-anchor="middle" font-family="#{FONT_FAMILY}" font-size="10" font-weight="400" fill="#{text_color}">),
        initials,
        '</text></svg>'
      ].join
    end

    private

    def text_color
      Constants::USER_AVATAR_LIGHT_TEXT_COLORS.include?(@user.avatar_color) ? LIGHT_TEXT_COLOR : DARK_TEXT_COLOR
    end
  end
end
