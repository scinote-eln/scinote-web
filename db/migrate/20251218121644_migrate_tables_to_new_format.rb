class MigrateTablesToNewFormat < ActiveRecord::Migration[7.2]
  def change

    #old format:
    # {state:
      # {
      #    "time"=>1766060619860,
      #    "order"=>[[3, "asc"]],
      #    "start"=>0,
      #    "length"=>10,
      #    "search"=>{"regex"=>false, "smart"=>true, "search"=>"", "caseInsensitive"=>true},
      #    "columns"=>[
      #      {"search"=>{"regex"=>false, "smart"=>true, "search"=>"", "caseInsensitive"=>true}, "visible"=>true},
      #      {"search"=>{"regex"=>false, "smart"=>true, "search"=>"", "caseInsensitive"=>true}, "visible"=>true},
      #      {"search"=>{"regex"=>false, "smart"=>true, "search"=>"", "caseInsensitive"=>true}, "visible"=>true},
      #      {"search"=>{"regex"=>false, "smart"=>true, "search"=>"", "caseInsensitive"=>true}, "visible"=>true},
      #      {"search"=>{"regex"=>false, "smart"=>true, "search"=>"", "caseInsensitive"=>true}, "visible"=>false},
      #      {"search"=>{"regex"=>false, "smart"=>true, "search"=>"", "caseInsensitive"=>true}, "visible"=>true},
      #      {"search"=>{"regex"=>false, "smart"=>true, "search"=>"", "caseInsensitive"=>true}, "visible"=>true},
      #      {"search"=>{"regex"=>false, "smart"=>true, "search"=>"", "caseInsensitive"=>true}, "visible"=>false},
      #      {"search"=>{"regex"=>false, "smart"=>true, "search"=>"", "caseInsensitive"=>true}, "visible"=>false},
      #      {"search"=>{"regex"=>false, "smart"=>true, "search"=>"", "caseInsensitive"=>true}, "visible"=>false},
      #      {"search"=>{"regex"=>false, "smart"=>true, "search"=>"", "caseInsensitive"=>true}, "visible"=>false},
      #      {"search"=>{"regex"=>false, "smart"=>true, "search"=>"", "caseInsensitive"=>true}, "visible"=>true}],
      #    "ColSizes"=>[30, 127, 239, 378, 301, 277, 277],
      #    "ColReorder"=>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
      #}
    #}

    #new format:
    # {"columnsState"=>
    #   [
    #     {
    #        "colId"=>"checkbox",
    #        "width"=>40,
    #        "hide"=>false,
    #        "pinned"=>"left",
    #        "sort"=>nil,
    #        "sortIndex"=>nil,
    #        "aggFunc"=>nil,
    #        "rowGroup"=>false,
    #        "rowGroupIndex"=>nil,
    #        "pivot"=>false,
    #        "pivotIndex"=>nil,
    #        "flex"=>nil
    #      },
    #      {
    #        "colId"=>"name",
    #        "width"=>200,
    #        "hide"=>false,
    #       "pinned"=>"left",
    #        "sort"=>nil,
    #        "sortIndex"=>nil,
    #        "aggFunc"=>nil,
    #        "rowGroup"=>false,
    #        "rowGroupIndex"=>nil,
    #        "pivot"=>false,
    #        "pivotIndex"=>nil,
    #       "flex"=>nil
    #      },
    #      ...
    #    ],
    #    "order"=>{"column"=>"name", "dir"=>"asc"},
    #    "currentViewRender"=>"table",
    #    "perPage"=>20
    #}


    # Basic columns that are always present:

    basic_columns = [
      'checkbox',
      'assigned',
      'id',
      'name',
      'created_at',
      'created_by',
      'updated_at',
      'updated_by',
      'archived_at',
      'archived_by',
      'external_id',
    ]

    RepositoryTableState.find_each do |table_state|
      old_state = table_state.state || {}
      columns = []

      basic_columns.each_with_index do |col_id, index|
        col_state = {}
        col_state['colId'] = col_id
        col_state['width'] = old_state['ColSizes'][index]
        col_state['hide'] = old_state['columns'][index]['visible']
        col_state['pinned'] = nil
        col_state['sort'] = nil
        col_state['sortIndex'] = nil
        col_state['aggFunc'] = nil
        col_state['rowGroup'] = false
        col_state['rowGroupIndex'] = nil
        col_state['pivot'] = false
        col_state['pivotIndex'] = nil
        col_state['flex'] = nil
        columns << col_state
      end

      if table_state.repository
        table_state.repository.repository_columns.order(:id).each_with_index do |repo_col, idx|
          col_index = basic_columns.length + idx
          col_state = {}
          col_state['colId'] = "column_#{repo_col.id}"
          col_state['width'] = old_state['ColSizes'][col_index]
          col_state['hide'] = old_state['columns'][col_index]['visible']
          col_state['pinned'] = nil
          col_state['sort'] = nil
          col_state['sortIndex'] = nil
          col_state['aggFunc'] = nil
          col_state['rowGroup'] = false
          col_state['rowGroupIndex'] = nil
          col_state['pivot'] = false
          col_state['pivotIndex'] = nil
          col_state['flex'] = nil
          columns << col_state
        end
      end

      order = {
        column: columns[old_state['order'][0][0]]['colId'],
        dir: old_state['order'][0][1]
      }

      reorder_columns = []

      old_state['ColReorder'].each do |old_index|
        reorder_columns << columns[old_index]
      end

      new_state = {
        'columnsState' => reorder_columns,
        'order' => order,
        'perPage' => old_state['length']
      }

      # Save new state to user settings
    end
  end
end
