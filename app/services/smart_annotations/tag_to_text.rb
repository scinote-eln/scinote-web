# frozen_string_literal: true

module SmartAnnotations
  class TagToText
    attr_reader :text

    def initialize(user, team, text)
      parse_items_annotations(user, team, text)
      parse_users_annotations(user, team, @text)
    end

    private

    USER_REGEX = /\[\@(.*?)~([0-9a-zA-Z]+)\]/
    ITEMS_REGEX = /\[\#(.*?)~(prj|exp|tsk|rep_item)~([0-9a-zA-Z]+)\]/
    OBJECT_MAPPINGS = { prj: Project,
                        exp: Experiment,
                        tsk: MyModule,
                        rep_item: RepositoryRow }.freeze

    def parse_items_annotations(user, team, text)
      @text = text.gsub(ITEMS_REGEX) do |el|
        value = extract_values(el)
        type = value[:object_type]
        begin
          object = fetch_object(type, value[:object_id])
          # handle repository_items edge case
          if type == 'rep_item'
            repository_item(value[:name], user, team, type, object)
          else
            next unless object && SmartAnnotations::PermissionEval.check(user,
                                                                         team,
                                                                         type,
                                                                         object)
            SmartAnnotations::TextPreview.text(nil, type, object)
          end
        rescue ActiveRecord::RecordNotFound
          next
        end
      end
    end

    def parse_users_annotations(user, team, text)
      @text = text.gsub(USER_REGEX) do |el|
        match = el.match(USER_REGEX)
        user = User.find_by_id(match[2].base62_decode)
        next unless user
        next if UserTeam.where(user: user, team: team).empty?
        user.full_name
      end
    end

    def repository_item(name, user, team, type, object)
      if object
        return unless SmartAnnotations::PermissionEval.check(user, team, type, object)

        return SmartAnnotations::TextPreview.text(nil, type, object)
      end
      SmartAnnotations::TextPreview.text(name, type, object)
    end

    def extract_values(element)
      match = element.match(ITEMS_REGEX)
      {
        name: match[1],
        object_type: match[2],
        object_id: match[3].base62_decode
      }
    end

    def fetch_object(type, id)
      klass = OBJECT_MAPPINGS.fetch(type.to_sym) do
        raise ActiveRecord::RecordNotFound.new("#{type} does not exist")
      end
      klass.find_by_id(id)
    end
  end
end
