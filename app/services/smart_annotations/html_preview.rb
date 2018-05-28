# frozen_string_literal: true

module SmartAnnotations
  class HtmlPreview
    class << self
      def html(name, type, object)
        send("generate_#{type}_snippet", name, object)
      end

      private

      ROUTES = Rails.application.routes.url_helpers

      def generate_prj_snippet(_, object)
        if object.archived?
          return "<span class='sa-type'>Prj</span> <a href='" \
                 "#{ROUTES.projects_archive_path}'>#{object.name}</a>" \
                 "#{I18n.t('atwho.res.archived')}"
        end
        "<span class='sa-type'>Prj</span> " \
        "<a href='#{ROUTES.project_path(object)}'>#{object.name}</a>"
      end

      def generate_exp_snippet(_, object)
        if object.archived?
          return "<span class='sa-type'>Exp</span> <a href='" \
                 "#{ROUTES.experiment_archive_project_path(object.project)}'>" \
                 "#{object.name}</a> #{I18n.t('atwho.res.archived')}"
        end
        "<span class='sa-type'>Exp</span> " \
        "<a href='#{ROUTES.canvas_experiment_path(object)}'>#{object.name}</a>"
      end

      def generate_tsk_snippet(_, object)
        if object.archived?
          return "<span class='sa-type'>Tsk</span> <a href='" \
                 "#{ROUTES.module_archive_experiment_path(
                   object.experiment
                 )}'>#{object.name}</a> #{I18n.t('atwho.res.archived')}"
        end
        "<span class='sa-type'>Tsk</span> " \
        "<a href='#{ROUTES.protocols_my_module_path(object)}'>" \
        "#{object.name}</a>"
      end

      def generate_rep_item_snippet(name, object)
        if object
          repository_name = fetch_repository_name(object)
          return "<span class='sa-type'>" \
                 "#{trim_repository_name(repository_name)}</span> " \
                 "<a href='#{ROUTES.repository_row_path(object)}' " \
                 "class='record-info-link'>#{object.name}</a>"
        end
        "<span class='sa-type'>Inv</span> " \
        "#{name} #{I18n.t('atwho.res.deleted')}"
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
        repository = Repository.with_discarded.find_by_id(object.repository_id)
        return 'Inv' unless repository
        repository.name
      end
    end
  end
end
