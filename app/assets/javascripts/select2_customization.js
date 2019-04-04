/* global  PerfectScrollbar */
$.fn.extend({
  select2Multiple: function(config = {}) {
    var placeholder;
    var templateSelection;
    var select2;

    if (this.length === 0) return this;
    // Adding ID to each block
    placeholder = this[0].dataset.placeholder || '';
    if (this.next().find('.select2-selection').length > 0) return this;
    templateSelection = (state) => {
      return $('<span class="select2-block-body" data-select-id="' + state.id + '">'
        + (config.customSelection !== undefined ? config.customSelection(state) : state.text)
      + '</span>');
    };
    select2 = this.select2({
      closeOnSelect: false,
      multiple: true,
      ajax: config.ajax,
      placeholder: placeholder,
      templateSelection: templateSelection,
      sorter: function(data) {
        return data.sort(function(a, b) {
          var from = a.text.toLowerCase();
          var to = b.text.toLowerCase();
          var result = 0;
          if (from > to) {
            result = 1;
          } else if (from < to) {
            result = -1;
          }
          return result;
        });
      }
    });
    // Add dynamic size
    select2.next().css('width', '100%');

    // Placeholder fix for ajax fields
    if (config.ajax) {
      select2.next().find('.select2-search__field').css('width', 'auto');
    }

    // unlimited size
    if (config.unlimitedSize) {
      this[0].dataset.unlimitedSize = true;
      select2.next().find('.select2-selection').css('max-height', 'none');
      select2.next().find('.select2-selection .select2-selection__rendered').css('width', '100%');
    }

    // Create arrow
    $('<div class="select2-arrow"><span class="caret"></span></div>').appendTo(select2.next())
      .click(() => select2.next().find('.select2-selection').click());

    // select all check
    this[0].dataset.singleDisplay = config.singleDisplay || false;
    if (this[0].dataset.selectAll === 'true') {
      $.each($(this).find('option'), (index, e) => { e.selected = true; });
      this.trigger('change');
    }
    if (config.singleDisplay) {
      $(this).updateSingleName();
    }
    return select2
      // Adding select all button
      .on('select2:open', function() {
        var selectElement = this;
        var groups;
        var groupChildrens;
        var leftPosition = -310;
        var perfectScroll = new PerfectScrollbar($('.select2-results__options')[0], { wheelSpeed: 0.5 });
        setTimeout(() => {
          perfectScroll.update();
        }, 300);
        $('.select2-dropdown').removeClass('custom-group');
        $('.select2-selection').scrollTo(0);
        $('.select2_select_all').remove();

        // Adding select_all_button
        if (selectElement.dataset.selectAllButton !== undefined) {
          $('<div class="select2_select_all btn btn-default"><strong>' + selectElement.dataset.selectAllButton + '</strong></div>').prependTo('.select2-dropdown').on('click', function() {
            var scrollTo = $('.select2-results__options').scrollTop();
            var elementsToSelect = $.map($(selectElement).find('option'), e => e.value);
            if (
              $(selectElement).find('option:selected').length === elementsToSelect.length
              || config.ajax
            ) elementsToSelect = [];
            $(selectElement).val(elementsToSelect).trigger('change');
            $(selectElement).select2('close');
            $(selectElement).select2('open');
            $('.select2-results__options').scrollTo(scrollTo);
          });
        }

        if (selectElement.dataset.dropdownPosition === 'left') {
          $('.select2-dropdown').parent().addClass('left-position');
          if (selectElement.dataset.selectAllButton === undefined) {
            $('.select2-dropdown').parent().addClass('full');
          }
          if (window.innerWidth < 1200) {
            $('.select2-dropdown').css('left', '');
          } else {
            $('.select2-dropdown').css('left', leftPosition);
          }
          $(window).on('resize', () => {
            if (window.innerWidth < 1200) {
              $('.select2-dropdown').css('left', '');
            } else {
              $('.select2-dropdown').css('left', leftPosition);
            }
          });
        }
        // Adding select all group members event
        if (selectElement.dataset.selectByGroup === 'true') {
          $('.select2-dropdown').addClass('custom-group');
          setTimeout(() => {
            groups = $('.select2-dropdown').find('.select2-results__group');
            groups.click(e => {
              var newSelection = [];
              var scrollTo = $('.select2-results__options').scrollTop();
              var group = e.currentTarget;
              var childrens = $(selectElement).find('optgroup[label="' + group.innerHTML + '"] option');
              childrens = $.map(childrens, act => act.value);
              newSelection = ($(selectElement).val() || []).filter(function(i) {
                return childrens.indexOf(i) < 0;
              });
              if ($(selectElement).find(
                'optgroup[label="' + group.innerHTML + '"] option:selected'
              ).length !== childrens.length) {
                newSelection = newSelection.concat(childrens);
              }
              $(selectElement).val(newSelection).trigger('change');
              $(selectElement).select2('close');
              $(selectElement).select2('open');
              $('.select2-results__options').scrollTo(scrollTo);
            });

            $.each(groups, (index, e) => {
              groupChildrens = $(selectElement).find('optgroup[label="' + e.innerHTML + '"] option');
              $(e).parent()[0].dataset.customGroup = 'true';
              $(e).parent()[0].dataset.toogle = 'none';
              if ($(selectElement).find('optgroup[label="' + e.innerHTML + '"] option:selected').length === groupChildrens.length) {
                $(e).parent()[0].dataset.toogle = 'all';
              }
            });
          }, 0);
        }
      })
      // Prevent shake bug with multiple select
      .on('select2:open select2:close', function() {
        $('.select2-selection').scrollTo(0);
      })
      // Prevent opening window when deleteing selection
      .on('select2:unselect', function() {
        var resultWindow = $('.select2-container--open');
        if (resultWindow.length === 0) {
          $(this).select2('open');
        }
      })
      // Fxied scroll bug
      .on('select2:selecting select2:unselecting', function(e) {
        $(e.currentTarget).data('scrolltop', $('.select2-results__options').scrollTop());
        $('.select2-selection').scrollTo(0);
      })
      // Fxied scroll bug
      .on('select2:select select2:unselect change', function(e) {
        var groups;
        var groupChildrens;
        $('.select2-selection').scrollTo(0);
        $('.select2-results__options').scrollTop($(e.currentTarget).data('scrolltop'));
        if (this.dataset.singleDisplay === 'true') {
          $(this).updateSingleName();
        }

        if (this.dataset.selectByGroup === 'true') {
          groups = $('.select2-dropdown').find('.select2-results__group');
          $.each(groups, (index, act) => {
            groupChildrens = $(this).find('optgroup[label="' + act.innerHTML + '"] option');
            $(act).parent()[0].dataset.toogle = 'none';
            if ($(this).find('optgroup[label="' + act.innerHTML + '"] option:selected').length === groupChildrens.length) {
              $(act).parent()[0].dataset.toogle = 'all';
            }
          });
        }
      });
  },
  select2MultipleClearAll: function() {
    $(this).val([]).trigger('change');
  },
  // Create from multiple blocks single one with counter
  updateSingleName: function() {
    var template = '';
    var selectElement = this;
    var selectedOptions = selectElement.next().find('.select2-selection__choice');
    var optionsCounter = selectedOptions.length;
    var allOptionsSelected = this.find('option').length === optionsCounter;
    var optionText = allOptionsSelected ? this[0].dataset.selectMultipleAllSelected : optionsCounter + ' ' + this[0].dataset.selectMultipleName;
    if (optionsCounter > 1) {
      selectedOptions.remove();
      template = '<li class="select2-selection__choice">'
                  + '<span class="select2-selection__choice__remove" role="presentation">×</span>'
                    + optionText
                + '</li>';
      $(template).prependTo(selectElement.next().find('.select2-selection__rendered')).find('.select2-selection__choice__remove')
        .click(function() { selectElement.select2MultipleClearAll(); });
    }
  }
});
