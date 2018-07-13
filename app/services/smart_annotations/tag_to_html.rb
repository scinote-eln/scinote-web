# frozen_string_literal: true

require 'smart_annotations/permision_eval'
require 'smart_annotations/html_preview'

module SmartAnnotations
  class TagToHtml
    attr_reader :html

    def initialize(user, text)
      parse(user, text)
    end

    private

    REGEX = /\[\#(.*?)~(prj|exp|tsk|rep_item)~([0-9a-zA-Z]+)\]/
    OBJECT_MAPPINGS = { prj: Project,
                        exp: Experiment,
                        tsk: MyModule,
                        rep_item: RepositoryRow }.freeze

    def parse(user, text)
      @html = text.gsub(REGEX) do |el|
        value = extract_values(el)
        type = value[:object_type]
        begin
          object = fetch_object(type, value[:object_id])
          # handle repository_items edge case
          if type == 'rep_item'
            repository_item(value[:name], user, type, object)
          else
            next unless object && SmartAnnotations::PermissionEval.check(user,
                                                                         type,
                                                                         object)
            SmartAnnotations::HtmlPreview.html(nil, type, object)
          end
        rescue ActiveRecord::RecordNotFound
          next
        end
      end
    end

    def repository_item(name, user, type, object)
      if object
        return unless SmartAnnotations::PermissionEval.check(user, type, object)
        return SmartAnnotations::HtmlPreview.html(nil, type, object)
      end
      SmartAnnotations::HtmlPreview.html(name, type, object)
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
      klass.find_by_id(id)
    end
  end
end
