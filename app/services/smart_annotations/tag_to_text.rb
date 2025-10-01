# frozen_string_literal: true

module SmartAnnotations
  class TagToText
    USER_REGEX = /\[@(.*?)~([0-9a-zA-Z]+)\]/
    ITEMS_REGEX = /\[\#(.*?)~(prj|exp|tsk|rep_item)~([0-9a-zA-Z]+)\]/

    attr_reader :text

    def initialize(user, team, text, is_shared_object: false)
      parse_items_annotations(user, team, text, is_shared_object)
      parse_users_annotations(user, team, @text, is_shared_object)
    end

    private

    OBJECT_MAPPINGS = { prj: Project,
                        exp: Experiment,
                        tsk: MyModule,
                        rep_item: RepositoryRow }.freeze

    def parse_items_annotations(user, team, text, is_shared_object)
      @text = text.gsub(ITEMS_REGEX) do |el|
        value = extract_values(el)
        type = value[:object_type]
        begin
          object = fetch_object(type, value[:object_id])
          # handle repository_items edge case
          if type == 'rep_item'
            repository_item(value[:name], user, team, type, object, is_shared_object)
          else
            if object && (is_shared_object || SmartAnnotations::PermissionEval.check(user, type, object))
              SmartAnnotations::TextPreview.text(nil, type, object)
            else
              private_placeholder(object)
            end
          end
        rescue ActiveRecord::RecordNotFound
          next
        end
      end
    end

    def parse_users_annotations(user, team, text, is_shared_object)
      @text = text.gsub(USER_REGEX) do |el|
        match = el.match(USER_REGEX)

        user = if is_shared_object
                 User.find_by(id: match[2].base62_decode)
               else
                 team.users.find_by(id: match[2].base62_decode)
               end
        next unless user

        user.full_name
      end
    end

    def repository_item(name, user, team, type, object, is_shared_object)
      if object
        return private_placeholder(object) unless is_shared_object || SmartAnnotations::PermissionEval.check(user, type, object)

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

    def private_placeholder(object = nil)
      case object
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
    end
  end
end
