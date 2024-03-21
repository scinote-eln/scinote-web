# frozen_string_literal: true

module SmartAnnotations
  class HtmlPreview
    class << self
      def html(name, type, object, preview_repository = false)
        if preview_repository
          send('generate_rep_snippet', name, object)
        else
          send("generate_#{type}_snippet", name, object)
        end
      end

      private

      ROUTES = Rails.application.routes.url_helpers

      def generate_prj_snippet(_, object)
        return "<span class='sa-type'>Prj</span>#{object.name} #{I18n.t('atwho.res.archived')}" if object.archived?

        "<a class='sa-link' href='#{ROUTES.experiments_path(project_id: object)}'>" \
          "<span class='sa-type'>Prj</span>#{object.name}</a>"
      end

      def generate_exp_snippet(_, object)
        if object.archived? || object.project.archived?
          return "<span class='sa-type'>Exp</span>#{object.name} #{I18n.t('atwho.res.archived')}"
        end

        "<a class='sa-link' href='#{ROUTES.my_modules_experiment_path(object)}'>" \
          "<span class='sa-type'>Exp</span>#{object.name}</a>"
      end

      def generate_tsk_snippet(_, object)
        if object.archived? || object.experiment.archived? || object.experiment.project.archived?
          return "<span class='sa-type'>Tsk</span>#{object.name} #{I18n.t('atwho.res.archived')}"
        end

        "<a class='sa-link' href='#{ROUTES.protocols_my_module_path(object)}'>" \
          "<span class='sa-type'>Tsk</span>#{object.name}</a>"
      end

      def generate_rep_item_snippet(name, object)
        if object&.repository
          repository_name = fetch_repository_name(object)
          "<a href='#{ROUTES.repository_repository_row_path(object.repository, object)}' " \
            "class='sa-link record-info-link'><span class='sa-type'>#{trim_repository_name(repository_name)}</span>" \
            "#{object.name} #{object.archived? ? I18n.t('atwho.res.archived') : ''}</a>"
        else
          "<span class='sa-type'>Inv</span> #{name} #{I18n.t('atwho.res.deleted')}"
        end
      end

      def generate_rep_snippet(name, object)
        if object&.repository
          repository_name = fetch_repository_name(object)
          "<a class='sa-link' href='#{ROUTES.repository_path(object.repository)}' " \
            "><span class='sa-type'>#{trim_repository_name(repository_name)}</span>" \
            "#{object.name} #{object.archived? ? I18n.t('atwho.res.archived') : ''}</a>"
        else
          "<span class='sa-type'>Inv</span> #{name} #{I18n.t('atwho.res.deleted')}"
        end
      end

      def trim_repository_name(name)
        splited_name = name.split
        size = splited_name.size
        return name.strip.slice(0..2).capitalize if size == 1

        generate_name_from_array(splited_name, size).capitalize
      end

      def generate_name_from_array(names, size)
        return "#{names[0].slice(0..1)}#{names[1][0]}" if size == 2

        "#{names[0][0]}#{names[1][0]}#{names[2][0]}"
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
