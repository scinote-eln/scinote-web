module ClientApi
  module Users
    module UserTeamsHelper
      def retrive_role_name(index)
        return unless index
        ['Guest', 'Normal user', 'Administrator'].at(index)
      end
    end
  end
end
