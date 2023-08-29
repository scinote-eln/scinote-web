# frozen_string_literal: true

module SmartAnnotations
  class TagToHtml
    REGEX = /\[\#(.*?)~(prj|exp|tsk|rep_item)~([0-9a-zA-Z]+)\]/.freeze
    USER_REGEX = /\[@(.*?)~([0-9a-zA-Z]+)\]/.freeze
    attr_reader :html

    def initialize(user, team, text, preview_repository = false)
      parse(user, team, text, preview_repository)
    end

    private

    OBJECT_MAPPINGS = { prj: Project,
                        exp: Experiment,
                        tsk: MyModule,
                        rep_item: RepositoryRow }.freeze

    def parse(user, team, text, preview_repository = false)
      @html = text.gsub(REGEX) do |el|
        value = extract_values(el)
        type = value[:object_type]
        begin
          object = fetch_object(type, value[:object_id])
          # handle repository_items edge case
          if type == 'rep_item'
            repository_item(value[:name], user, team, type, object, preview_repository)
          else
            next unless object && SmartAnnotations::PermissionEval.check(user,
                                                                         team,
                                                                         type,
                                                                         object)
            SmartAnnotations::HtmlPreview.html(nil, type, object)
          end
        rescue ActiveRecord::RecordNotFound
          next
        end
      end
    end

    def repository_item(name, user, team, type, object, preview_repository)
      if object&.repository
        return unless SmartAnnotations::PermissionEval.check(user, team, type, object)

        return SmartAnnotations::HtmlPreview.html(nil, type, object, preview_repository)
      end
      SmartAnnotations::HtmlPreview.html(name, type, object, preview_repository)
    end

    def extract_values(element)
      match = element.match(REGEX)
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
      klass.find_by(id: id)
    end
  end
end
