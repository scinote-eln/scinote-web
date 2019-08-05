var dropdownSelector = (function() {
  function generateDropdown(selector){
    var selectElement = $(selector)
    var optionContainer;
    var dropdownContainer = selectElement.after('<div class="dropdown-selector-container"></div>').next()
    $(`
      <div class="input-field"></div>
      <input type="hidden" class="data-field" value="[]">
      <div class="dropdown-container"></div>
    `).appendTo(dropdownContainer)

    ps = new PerfectScrollbar(dropdownContainer.find('.dropdown-container')[0])
    activePSB.push(ps)

    optionContainer = dropdownContainer.find('.dropdown-container')

    dropdownContainer.find('.input-field').click(() => {
      optionContainer.find('.dropdown-group, .dropdown-option').remove()
      optionContainer.scrollTo(0)
      dropdownContainer.toggleClass("open")
      if (dropdownContainer.hasClass("open")) {
        loadData(selectElement , dropdownContainer)
        updateDropdownDirection(dropdownContainer)
      }
    })
    $(window).resize(function(){
      updateDropdownDirection(dropdownContainer)
    })

    $(window).click(() => {
      dropdownContainer.removeClass("open")
    });
    dropdownContainer.click((e) => {
      e.stopPropagation();
    })

    selectElement.css('display', 'none')
  } 

  function updateDropdownDirection(container) {
    var windowHeight = $(window).height()
    var containerPosition = container[0].getBoundingClientRect().top
    var containerHeight = container[0].getBoundingClientRect().height
    var bottomSpace = windowHeight - containerPosition - containerHeight
    if (bottomSpace < 232) {
      container.addClass('inverse')
      container.find('.dropdown-container').css('max-height', (containerPosition - 82) + 'px')
    } else {
      container.removeClass('inverse')
      container.find('.dropdown-container').css('max-height', (bottomSpace - 32) + 'px')
    }
  }

  function loadData(selector, container) {

    function drawOption(option) {
      return $(`
        <div class="dropdown-option checkbox-icon"
          data-label="${option.innerHTML}"
          data-value="${option.value}">
          ${option.innerHTML}
        </div>"
      `)
    }

    function drawGroup(group) {
      return $(`
        <div class="dropdown-group">
          <div class="group-name checkbox-icon">${group.label}</div>
        </div>
      `)
    }

    function clickOption() {
      $(this).toggleClass('select')
      saveData(selector, container)
    }
    

    if (selector.data('select-by-group')){
      var groups = selector.find('optgroup')
      $.each(groups, function(gi, group) {
        var groupElement = drawGroup(group)
        $.each($(group).find('option'), function(oi, option) {
          optionElement = drawOption(option)
          optionElement.click(clickOption)
          optionElement.appendTo(groupElement)
        })
        groupElement.find('.group-name').click(function() {
            var groupContainer = $(this).parent()
            if (groupContainer.toggleClass('select').hasClass('select')) {
              groupContainer.find('.dropdown-option').addClass('select')
            }else{
              groupContainer.find('.dropdown-option').removeClass('select')
            }
            saveData(selector, container)
          })
        groupElement.appendTo(container.find('.dropdown-container'))
      })
    } else {
      options = selector.find('option')
      $.each(options, function(oi, option) {
        optionElement = drawOption(option)
        optionElement.click(clickOption)
        optionElement.appendTo(container.find('.dropdown-container'))
      })
    }

    PerfectSb().update_all()

    $.each(JSON.parse(container.find('.data-field').val()), function(i, selectedOption) {
      container.find('.dropdown-container .dropdown-option[data-value="' + selectedOption.value + '"]').addClass('select')
    })
    if (selector.data('select-by-group')){
      $.each(container.find('.dropdown-group'), function(gi, group) {
        if ($(group).find('.dropdown-option').length === $(group).find('.dropdown-option.select').length) {
          $(group).addClass('select')
        }
      })
    }
  }

  function saveData(selector, container) {
    var oldSelect = JSON.parse(container.find('.data-field').val())
    var newSelect = []
    $.each(container.find('.dropdown-container .dropdown-option.select'), function(oi ,option){
      newSelect.push({
        label: option.dataset.label,
        value: option.dataset.value
      })
    })

    $.each(oldSelect, function(oldValue){
      
    })

    container.find('.data-field').val(JSON.stringify(selectArray))

    updateTags(selector, container)
  }

  function updateTags(selector, container) {
    selectedOptions = JSON.parse(container.find('.data-field').val())

    function drawTag(label, tagId) {
      var tag = $(`<div class="ds-tags" >
                  <div class="tag-label" data-ds-tag-id=${tagId}>${label}</div>
                  <i class="fas fa-times"></i>
                </div>`).appendTo(container.find('.input-field'))

      tag.click((e) => {e.stopPropagation()});
      tag.find('.fa-times').click(function(e) {
        var label = $(this).closest('.tag-label')
        e.stopPropagation()
        if (selector.data('combine-tags')) {
          container.find('.data-field').val('[]')
          $(this).parent().remove()
        } else {

        }
        updateDropdownDirection($(selector).next())
      });

      updateDropdownDirection($(selector).next())
    }


    if (selector.data('combine-tags')){
      container.find('.ds-tags').remove()
      if (selectedOptions.length === 1) {
        drawTag(selectedOptions[0].label, selectedOptions[0].value)
      } else if (allOptionsSelected(selector, container)) {
        drawTag(selector.data('select-multiple-all-selected'), 0)
      } else if (selectedOptions.length > 1) {
        drawTag(selectedOptions.length + ' ' + selector.data('select-multiple-name'), 0)
      }
    } else {

    }
  }


  function allOptionsSelected(selector, container){
    return container.find('.data-field').val().length === selector.find('option').length && !(selector.data('ajax-data'))
  }


  return {
    init: (selector) => {
      generateDropdown(selector)
    },
    update_dropdown_position: (selector) => {
      updateDropdownDirection($(selector).next())
    }
  };
}());