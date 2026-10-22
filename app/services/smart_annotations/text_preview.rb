# frozen_string_literal: true

module SmartAnnotations
  class TextPreview
    class << self
      def text(name, type, object, add_prefix_type: false, page: nil)
        text = type == 'file' ? generate_file_snippet(name, object, page) : send("generate_#{type}_snippet", name, object)
        return text unless add_prefix_type

        prefix_text = case type
                      when 'rep_item'
                        if object&.repository
                          repository_name = fetch_repository_name(object)
                          "[#{trim_repository_name(repository_name)}]"
                        else
                          I18n.t('atwho.tags.rep')
                        end
                      else
                        I18n.t("atwho.tags.#{type}")
                      end

        "#{prefix_text}#{text}"
      end

      private

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

      def generate_file_snippet(name, object, page = nil)
        return "#{name} #{I18n.t('atwho.res.deleted')}" if object.nil?
        return "#{file_label(object, page)} #{I18n.t('atwho.res.archived')}" if object.archived? || file_my_module_archived?(object)

        file_label(object, page)
      end

      def file_label(object, page)
        label = "#{object.file_title.presence || object.file_name}_#{object.code}"
        page.present? ? "#{label}_p#{page}" : label
      end

      def file_my_module_archived?(object)
        my_module = object.my_module
        return false unless my_module

        my_module.archived? || my_module.experiment.archived? || my_module.experiment.project.archived?
      end

      def trim_repository_name(name)
        words = name.to_s.split

        abbreviation = case words.size
                       when 0 then ''
                       when 1 then words.first[0, 3]
                       when 2 then words.first[0, 2] + words.last[0]
                       else        words.first(3).map { |word| word[0] }.join
                       end

        abbreviation.capitalize
      end

      def fetch_repository_name(object)
        return object.repository.name if object.repository

        repository = Repository.with_discarded.find_by(id: object.repository_id)
        return 'Inv' unless repository

        repository.name
      end
    end
  end
end
