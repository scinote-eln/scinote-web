# frozen_string_literal: true

module SmartAnnotations
  class TagToHtml
    ALL_REGEX = /\[(@(.*?)|\#(.*?)~(prj|exp|tsk|rep_item))~([0-9a-zA-Z]+)\]/
    ITEMS_REGEX = /\[\#(.*?)~(prj|exp|tsk|rep_item)~([0-9a-zA-Z]+)\]/
    USER_REGEX = /\[@(.*?)~([0-9a-zA-Z]+)\]/
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
      @html = text.gsub(ITEMS_REGEX) do |el|
        value = extract_values(el)
        type = value[:object_type]
        begin
          object = fetch_object(type, value[:object_id])
          # handle repository_items edge case
          if type == 'rep_item'
            repository_item(value[:name], user, team, type, object, preview_repository)
          else
            if object && SmartAnnotations::PermissionEval.check(user, type, object)
              SmartAnnotations::HtmlPreview.html(nil, type, object)
            else
              private_placeholder(object)
            end
          end
        rescue ActiveRecord::RecordNotFound
          next
        end
      end
    end

    def repository_item(name, user, team, type, object, preview_repository)
      if object&.repository
        return private_placeholder(object) unless SmartAnnotations::PermissionEval.check(user, type, object)

        return SmartAnnotations::HtmlPreview.html(nil, type, object, preview_repository)
      end
      SmartAnnotations::HtmlPreview.html(name, type, object, preview_repository)
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
      klass.find_by(id: id)
    end

    def private_placeholder(object = nil)
      label = case object
              when Project
                I18n.t('smart_annotations.private.project')
              when Experiment
                I18n.t('smart_annotations.private.experiment')
              when MyModule
                I18n.t('smart_annotations.private.my_module')
              when RepositoryRow
                I18n.t('smart_annotations.private.repository_row')
              else
                I18n.t('smart_annotations.private.object')
              end

      "<span class=\"text-sn-grey\">#{label}</span>"
    end
  end
end
