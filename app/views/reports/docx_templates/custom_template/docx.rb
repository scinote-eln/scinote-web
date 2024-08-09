# frozen_string_literal: true

module CustomTemplateDocx
  def prepare_docx
    report_name = get_template_value('custom_docx_report_name')
    report_number = get_template_value('custom_docx_report_number')

    @project_members = @report.project&.users

    report_authors = @project_members.where(id: get_template_value('custom_docx_author[]')).pluck(:full_name).join(', ')
    report_reviewers = @project_members.where(id: get_template_value('custom_docx_reviewer[]')).pluck(:full_name).join(', ')
    report_author_role = get_template_value('custom_docx_author_role')
    report_reviewer_role = get_template_value('custom_docx_reviewer_role')

    @docx.header do |header|
      header.table [[report_name, 'custom report']] do
        border_size 1
        cell_style cols[0], width: 8000
        cell_style cols[1], width: 2800
      end
    end

    @docx.footer do |footer|
      pages = Caracal::Core::Models::TableCellModel.new do
        p do
          field :page
          text ' of '
          field :numpages
        end
      end
      footer.table [['Confidential', pages]] do
        border_top do
          size 1
        end
        cell_style cols[0], width: 9500
        cell_style cols[1], width: 1000
      end
    end

    @docx.p

    logo_data = File.read(Rails.root.join('app/assets/images/scinote_logo.png'))

    c1 = Caracal::Core::Models::TableCellModel.new do
      p report_name, bold: true
      p ''
    end

    c2 = Caracal::Core::Models::TableCellModel.new do
      img 'logo.png' do
        data logo_data
        height 20
        width 100
        align :left
      end
    end

    c3 = Caracal::Core::Models::TableCellModel.new do
      p "Author: #{report_authors}"
      p "Role: #{report_author_role}"
    end

    c4 = Caracal::Core::Models::TableCellModel.new do
      p "Reviewer: #{report_reviewers}"
      p "Role: #{report_reviewer_role}"
    end

    c5 = Caracal::Core::Models::TableCellModel.new do
      p "Report number:"
      p report_number
    end

    @docx.table [[c1, c2], [c3, c4, c5]] do
      border_size 2
      cell_style rows[0], width: 3500
      cell_style rows[1], width: 3500
      cell_style rows[0][0], colspan: 2
    end

    @docx.p

    @docx.table_of_contents do |toc|
      toc.title 'Table of Contents'
      toc.opts 'TOC \o "1-4" \h \z \u \t "Heading 5,1"'
    end

    @docx.page

    my_modules_elements = []
    @report.root_elements.each do |subject|
      my_modules_elements += subject.children.active if subject.type_of == 'experiment'
    end

    @my_modules = MyModule.where(id: my_modules_elements.map { |element| element.my_module.id })

    @docx.h1 'Chapter 1'
    @docx.h2 'Sub chapter 1' if get_template_value('custom_docx_sub_chapter_1')
    @docx.h2 'Sub chapter 2' if get_template_value('custom_docx_sub_chapter_2')
    @docx.h1 'Chapter 2'
    if get_template_value('custom_docx_sub_chapter_3')
      @docx.h2 'Sub chapter 3 with inventory'
      draw_repositories(get_template_value('custom_docx_sub_chapter_3_inventories[]'))
    end
    if get_template_value('custom_docx_sub_chapter_4')
      @docx.h2 'Sub chapter 4 with inventory'
      draw_repositories(get_template_value('custom_docx_sub_chapter_4_inventories[]'))
    end
    @docx.h2 'Sub chapter 5' if get_template_value('custom_docx_sub_chapter_5')
    @docx.h2 'Sub chapter 6' if get_template_value('custom_docx_sub_chapter_6')
    @docx.h2 'Sub chapter 7' if get_template_value('custom_docx_sub_chapter_7')
    @docx.h1 'Chapter 3'
    if get_template_value('custom_docx_sub_chapter_8')
      @docx.h2 'Sub chapter 8 with task'
      my_modules_elements.each do |element|
        draw_my_module(element, without_results: true, without_repositories: true)
      end
    end
    @docx.h2 'Sub chapter 9' if get_template_value('custom_docx_sub_chapter_9')
    @docx.h2 'Sub chapter 10' if get_template_value('custom_docx_sub_chapter_10')
    @docx.h2 'Sub chapter 11' if get_template_value('custom_docx_sub_chapter_11')
    if get_template_value('custom_docx_sub_chapter_12')
      @docx.h2 'Sub chapter 12'
      @docx.h3 'Sub sub chapter 1' if get_template_value('custom_docx_sub_sub_chapter_1')
      @docx.h3 'Sub sub chapter 2' if get_template_value('custom_docx_sub_sub_chapter_2')
    end
    @docx.h1 'Chapter 4'
    if get_template_value('custom_docx_sub_chapter_13')
      @docx.h2 'Sub chapter 13 with results'
      my_modules_elements.each do |element|
        draw_results(element.my_module)
      end
    end
    @docx.h2 'Sub chapter 14' if get_template_value('custom_docx_sub_chapter_14')
    @docx.h2 'Sub chapter 15' if get_template_value('custom_docx_sub_chapter_15')
    @docx.h2 'Sub chapter 16' if get_template_value('custom_docx_sub_chapter_16')
    @docx.h2 'Sub chapter 17' if get_template_value('custom_docx_sub_chapter_17')
    @docx.h1 'Chapter 5'
  end

  def repository_docx_json(repository, rows)
    headers = [
      I18n.t('repositories.table.id'),
      I18n.t('repositories.table.row_name'),
      I18n.t('repositories.table.added_on'),
      I18n.t('repositories.table.added_by')
    ]
    custom_columns = []
    return false unless repository

    repository.repository_columns.order(:id).each do |column|
      headers.push(column.name)
      custom_columns.push(column.id)
    end

    records = repository.repository_rows.where(id: rows)
                        .select(:id, :name, :created_at, :created_by_id, :repository_id, :parent_id, :archived)
    { headers: headers, rows: records, custom_columns: custom_columns }
  end

  def load_repositories(repositories_id)
    live_repositories = Repository.accessible_by_teams(@report.team).where(id: repositories_id).sort_by { |r| r.name.downcase }
    snapshots_of_deleted = RepositorySnapshot.left_outer_joins(:original_repository)
                                             .where(team: @report.team)
                                             .where(parent_id: repositories_id)
                                             .where.not(original_repository: live_repositories)
                                             .select('DISTINCT ON ("repositories"."parent_id") "repositories".*')
                                             .sort_by { |r| r.name.downcase }
    live_repositories + snapshots_of_deleted
  end

  def draw_repositories(repositories_id)
    load_repositories(repositories_id).each do |repository|
      rows = repository.repository_rows.where(id: @my_modules.joins(:my_module_repository_rows).select(:repository_row_id)).select(:id)
      repository_data = repository_docx_json(repository, rows)

      next unless repository_data[:rows].any? && can_read_repository?(@user, repository)

      table = prepare_row_columns(repository_data, nil, repository)

      @docx.p
      @docx.p repository.name, bold: true, size: Constants::REPORT_DOCX_STEP_ELEMENTS_TITLE_SIZE
      @docx.table table, border_size: Constants::REPORT_DOCX_TABLE_BORDER_SIZE

      @docx.p
      @docx.p
    end
  end
end
