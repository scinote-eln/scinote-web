# frozen_string_literal: true

module Users
  class SessionsManagementController < ApplicationController
    include Devise::Controllers::Rememberable

    before_action :check_serverside_sessions_enabled
    before_action :load_user_session, only: :destroy

    def index
      current_ids = UserSession.current_session_ids(request)
      user_sessions = UserSession.for_user(current_user).active(current_user).order(updated_at: :desc).to_a
      user_sessions.sort_by! { |s| current_ids.include?(s.session_id) ? 0 : 1 }

      render json: {
        data: user_sessions.map { |user_session| serialize_session(user_session, current_ids) }
      }
    end

    def destroy
      if UserSession.current_session_ids(request).include?(@user_session.session_id)
        return render json: { error: I18n.t('users.registrations.edit.sessions.cannot_terminate_current') },
                      status: :unprocessable_content
      end

      @user_session.destroy!
      invalidate_remember_me_tokens
      render json: {}
    end

    def destroy_others
      UserSession.for_user(current_user).where.not(session_id: UserSession.current_session_ids(request)).delete_all
      invalidate_remember_me_tokens
      render json: {}
    end

    private

    def check_serverside_sessions_enabled
      render_404 unless Rails.configuration.x.serverside_sessions_enabled
    end

    # Without this, a terminated browser with a "remember me" cookie would be signed right back in.
    # Devise only supports invalidating all remember tokens of a user, so we re-issue the token
    # for the current browser, if it had one.
    def invalidate_remember_me_tokens
      remembered = cookies.signed[remember_key(current_user, :user)].present?
      current_user.forget_me!
      remember_me(current_user) if remembered
    end

    def load_user_session
      @user_session = UserSession.for_user(current_user).find_by(id: params[:id])
      render_404 if @user_session.blank?
    end

    def serialize_session(user_session, current_ids)
      {
        id: user_session.id,
        user_agent: user_session.user_agent.presence || I18n.t('users.registrations.edit.sessions.unknown_device'),
        ip_address: user_session.ip_address,
        signed_in_at: I18n.l(user_session.signed_in_at, format: :full),
        last_seen_at: I18n.l(user_session.last_seen_at, format: :full),
        current: current_ids.include?(user_session.session_id),
        destroy_url: sessions_management_path(user_session.id)
      }
    end
  end
end
