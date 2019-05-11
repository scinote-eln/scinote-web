/* global  PerfectScrollbar */
$.fn.extend({
  select2Multiple: function(config = {}) {
    var placeholder;
    var templateSelection;
    var select2;
    var templateResult;

    if (this.length === 0) return this;
    // Adding ID to each block
    placeholder = this[0].dataset.placeholder || '';
    if (this.next().find('.select2-selection').length > 0) return this;
    templateSelection = (state, parent) => {
      if (config.colorField !== undefined) {
        parent.css('background', state[config.colorField] || state.element.dataset[config.colorField]);
      }
      return $('<span class="select2-block-body" data-select-id="' + state.id + '">'
        + (config.customSelection !== undefined ? config.customSelection(state) : state.text)
      + '</span>');
    };

    templateResult = (state) => {
      if (config.templateResult) {
        return config.templateResult(state);
      }
      return state.text;
    };


    select2 = this.select2({
      multiple: true,
      ajax: config.ajax,
      placeholder: placeholder,
      templateSelection: templateSelection,
      templateResult: templateResult,
      closeOnSelect: config.closeOnSelect || false,
      tags: config.dynamicCreation || false,
      tokenSeparators: config.dynamicCreationDelimiter || [','],
      sorter: function(data) {
        if (data.length === 0) return data;
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
      setTimeout(() => {
        select2.next().find('.select2-search__field').css(
          'width', config.placeholderSize || 'auto'
        );
      }, 0);
    }

    // Check that group select correctly
    function select2CheckGroups() {
      var select2Object = $('select[data-select-by-group="true"][data-open-dropdown="true"]');
      var groups = $('.select2-dropdown').find('.select2-results__group');
      $.each(groups, (i, e) => {
        var groupChildrens = $(select2Object).find('optgroup[label="' + e.innerHTML + '"] option');
        $(e).parent()[0].dataset.customGroup = 'true';
        $(e).parent()[0].dataset.toogle = 'none';
        if ($(select2Object).find('optgroup[label="' + e.innerHTML + '"] option:selected').length === groupChildrens.length) {
          $(e).parent()[0].dataset.toogle = 'all';
        }
      });
    }

    function select2ScrollToSelectedElement() {
      var activeElement;
      var sel = $('.select2-results .select2-results__option[role="treeitem"]');
      var parent;
      var activeElementTopPosition;
      var parentActiveElementTopPosition;
      var fullTopPosition;
      var containerRealPosition;
      var containerScrollPosition = $('.select2-results__options').scrollTop();
      var containerHeight = $('.select2-results__options').height();
      if ($('.select2-results').length > 0 && $('.select2-results')[0].dataset.lastSelected !== 'false') {
        activeElement = sel[parseInt($('.select2-results')[0].dataset.lastSelected, 10)];
      } else {
        return;
      }
      parent = $(activeElement).parents('.select2-results__option[role="group"]');
      if (parent.length === 0) return;
      activeElementTopPosition = $(activeElement).position().top;
      parentActiveElementTopPosition = parent.position().top;
      fullTopPosition = activeElementTopPosition + parentActiveElementTopPosition;
      containerRealPosition = containerScrollPosition - containerHeight;
      $('.select2-results__options').scrollTop(fullTopPosition + containerRealPosition + 130);
    }

    // listen for keyups dropdown
    $('body').off('keyup', '.select2')
      .on('keyup', '.select2', function(e) {
        var keys = { up: 38, down: 40 };
        var sel = $('.select2-results');
        var childSelector = '.select2-results__option[role="treeitem"]';
        var startElement = sel.find(childSelector + '.arrow_pointer');
        var startPosition = 0;
        var newPosition;
        var newElement;
        if (e.keyCode !== keys.up && e.keyCode !== keys.down) {
          select2CheckGroups();
          return;
        }
        sel.blur();

        sel.find(childSelector).each((i, child) => {
          if (child.className.includes('arrow_pointer')) startPosition = i;
        });
        if (startElement.length === 0) {
          if ($('.select2-results')[0].dataset.lastSelected !== 'false') {
            startPosition = parseInt($('.select2-results')[0].dataset.lastSelected, 10);
          } else {
            startElement = sel.find(childSelector).first().addClass('arrow_pointer');
            $('.select2-results')[0].dataset.lastSelected = startPosition;
            return;
          }
        }

        if (e.keyCode === keys.down && !e.altKey) {
          if ((startPosition + 1) === sel.find(childSelector).length) return;
          newPosition = startPosition + 1;
        } else if (e.keyCode === keys.up) {
          if ((startPosition - 1) === -1) return;
          newPosition = startPosition - 1;
        }
        newElement = sel.find(childSelector)[newPosition];
        newElement.className += ' arrow_pointer';
        $('.select2-results')[0].dataset.lastSelected = newPosition;
        startElement.removeClass('arrow_pointer');
        select2ScrollToSelectedElement();
        select2CheckGroups();
      });

    $('.select2').find('input, .select2-selection__rendered').off('keydown').on('keydown', function(e) {
      var activeElement = $('.select2-results .arrow_pointer');
      var firstElement = $('.select2-results .select2-results__option').first();
      var groupElement = activeElement.find('.select2-results__group');
      if (e.keyCode === 13) {
        if (groupElement.length > 0) {
          groupElement.click();
        } else if (activeElement.length > 0) {
          activeElement.mouseup();
        } else {
          firstElement.mouseup();
        }

        setTimeout(() => {
          select2CheckGroups();
        }, 0);

        e.preventDefault();
        e.stopPropagation();
      }
      if ([37, 38, 39, 40].indexOf(e.keyCode) > -1) {
        select2ScrollToSelectedElement();
        e.preventDefault();
      }
    });

    // Add dynamic size
    select2.next().css('width', '100%');

    // unlimited size
    if (config.unlimitedSize) {
      this[0].dataset.unlimitedSize = true;
      select2.next().find('.select2-selection').css('max-height', 'none');
      select2.next().find('.select2-selection .select2-selection__rendered').css('width', '100%');
    }

    // Create arrow
    if (!(config.withoutArrow)) {
      $('<div class="select2-arrow"><span class="caret"></span></div>').appendTo(select2.next())
        .click(() => select2.next().find('.select2-selection').click());
    }
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
        var perfectScroll = new PerfectScrollbar($('.select2-results__options')[0], {
          wheelSpeed: 0.5,
          handlers: ['click-rail', 'drag-thumb', 'wheel', 'touch']
        });
        setTimeout(() => {
          perfectScroll.update();
        }, 300);
        $('.select2-results')[0].dataset.lastSelected = false;
        selectElement.dataset.openDropdown = 'true';
        $('.select2-dropdown').removeClass('custom-group').addClass(selectElement.id + '-dropdown');
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
            groups.off('click').click(e => {
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
      .on('select2:close', function() {
        this.dataset.openDropdown = 'false';
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
      .on('change', function(e) {
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
        setTimeout(() => {
          select2ScrollToSelectedElement();
        }, 0);
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
