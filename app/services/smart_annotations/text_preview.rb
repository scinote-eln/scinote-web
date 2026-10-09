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

      def generate_rep_snippet(name, object)
        return "#{name} #{I18n.t('atwho.res.deleted')}" if object.nil?
        return "#{object.name} #{I18n.t('atwho.res.archived')}" if object.archived?

        object.name
      end

      def generate_file_snippet(_, object)
        return I18n.t('atwho.res.deleted') if object.nil?
        return "#{object.file_name} #{I18n.t('atwho.res.archived')}" if object.archived? || file_my_module_archived?(object)

        object.file_name
      end

      def file_my_module_archived?(object)
        my_module = object.my_module
        return false unless my_module

        my_module.archived? || my_module.experiment.archived? || my_module.experiment.project.archived?
      end
    end
  end
end
