module ClientApi
  module Teams
    class CreateService < BaseService
      attr_accessor :team

      def execute
        @team = Team.new(@params)
        @team.created_by = @current_user

        if @team.save
          # Okay, team is created, now
          # add the current user as admin
          UserTeam.create(
            user: @current_user,
            team: @team,
            role: 2
          )

          success
        else
          error(@team.errors.full_messages.uniq.join('. '))
        end
      end
    end
  end
end
