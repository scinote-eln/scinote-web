# frozen_string_literal: true

module SmartAnnotations
  class Preview
    class << self
      def html(name, type, object)
        send("generate_#{type}_snippet", name, object)
      end

      private

      ROUTES = Rails.application.routes.url_helpers

      def generate_prj_snippet(_, object)
        if object.archived?
          return "<span class='sa-type'>PRJ</span><a href='" \
                 "#{ROUTES.projects_archive_path}'>#{object.name}</a>" \
                 "#{I18n.t('atwho.res.archived')}"
        end
        "<span class='sa-type'>PRJ</span>" \
        "<a href='#{ROUTES.project_path(object)}'>#{object.name}</a>"
      end

      def generate_exp_snippet(_, object)
        if object.archived?
          return "<span class='sa-type'>EXP</span><a href='" \
                 "#{ROUTES.experiment_archive_project_path(object.project)}'>" \
                 "#{object.name}</a> #{I18n.t('atwho.res.archived')}"
        end
        "<span class='sa-type'>EXP</span>" \
        "<a href='#{ROUTES.canvas_experiment_path(object)}'>#{object.name}</a>"
      end

      def generate_tsk_snippet(_, object)
        if object.archived?
          return "<span class='sa-type'>TSK</span><a href='" \
                 "#{ROUTES.module_archive_experiment_path(
                   object.experiment
                 )}'>#{object.name}</a> #{I18n.t('atwho.res.archived')}"
        end
        "<span class='sa-type'>TSK</span>" \
        "<a href='#{ROUTES.protocols_my_module_path(object)}'>" \
        "#{object.name}</a>"
      end

      def generate_rep_item_snippet(name, object)
        if object
          repository_name = object.repository.name
          return "<span class='sa-type'>" \
                 "#{trim_repository_name(repository_name)}</span>" \
                 "<a href='#{ROUTES.repository_row_path(object)}' " \
                 "class='record-info-link'>#{object.name}</a>"
        end
        "<span class='sa-type'>REP</span>" \
        "#{name} #{I18n.t('atwho.res.deleted')}"
      end

      def trim_repository_name(name)
        name.strip.slice(0..2).capitalize
      end
    end
  end
end
