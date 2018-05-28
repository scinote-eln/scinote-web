# frozen_string_literal: true

module SmartAnnotations
  class TextPreview
    class << self
      def text(name, type, object)
        send("generate_#{type}_snippet", name, object)
      end

      private

      ROUTES = Rails.application.routes.url_helpers

      def generate_prj_snippet(_, object)
        if object.archived?
          return "#{object.name} #{I18n.t('atwho.res.archived')}"
        end
        object.name
      end

      def generate_exp_snippet(_, object)
        if object.archived?
          return "#{object.name} #{I18n.t('atwho.res.archived')}"
        end
        object.name
      end

      def generate_tsk_snippet(_, object)
        if object.archived?
          return "#{object.name} #{I18n.t('atwho.res.archived')}"
        end
        object.name
      end

      def generate_rep_item_snippet(name, object)
        if object
          return object.name
        end
        "#{name} #{I18n.t('atwho.res.deleted')}"
      end
    end
  end
end
