var dropdownSelector = (function() {
  function generateDropdown(selector){
    var selectElement = $(selector)
    var dropdownContainer = selectElement.after('<div class="dropdown-selector-container"></div>').next()
    $(`
      <div class="input-field"></div>
      <input type="hidden" class="data-field" value="[]">
      <div class="dropdown-container"></div>
    `).appendTo(dropdownContainer)

    ps = new PerfectScrollbar(dropdownContainer.find('.dropdown-container')[0])
    activePSB.push(ps)

    dropdownContainer.find('.input-field').click(() => {
      dropdownContainer.toggleClass("open")
      if (dropdownContainer.hasClass("open")) {
        loadData(selectElement , dropdownContainer)
        updateDropdownDirection(dropdownContainer)
      }
    })
    $(window).resize(function(){
      updateDropdownDirection(dropdownContainer)
    })

    dropdownContainer.blur(function() {
      console.log(1)
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

    container.find('.dropdown-container .dropdown-group').remove()
    container.find('.dropdown-container .dropdown-option').remove()

    if (selector.data('select-by-group')){
      var groups = selector.find('optgroup')
      $.each(groups, function(gi, group) {
        var groupElement = $(`
          <div class="dropdown-group">
            <div class="group-name checkbox-icon">`+ group.label + `</div>
          </div>
        `)
        $.each($(group).find('option'), function(oi, option) {
          optionElement = $(`
            <div class="dropdown-option checkbox-icon" data-value="` + option.value + `">
              ` + option.innerHTML + `
            </div>"
          `)
          optionElement.click(function() {
            $(this).toggleClass('select')
            saveData(container)
          })
          optionElement.appendTo(groupElement)
        })
        groupElement.find('.group-name').click(function() {
            var groupContainer = $(this).parent()
            groupContainer.toggleClass('select')
            if (groupContainer.hasClass('select')) {
              groupContainer.find('.dropdown-option').addClass('select')
            }else{
              groupContainer.find('.dropdown-option').removeClass('select')
            }
            saveData(container)
          })
        groupElement.appendTo(container.find('.dropdown-container'))
      })
    } else {
      options = selector.find('option')
      $.each(options, function(oi, option) {
        optionElement = $(`
          <div class="dropdown-option checkbox-icon" data-value="` + option.value + `">
            ` + option.innerHTML + `
          </div>"
        `)
        optionElement.click(function() {
          $(this).toggleClass('select')
          saveData(container)
        })
        optionElement.appendTo(container.find('.dropdown-container'))
      })
    }

    PerfectSb().update_all()

    $.each(JSON.parse(container.find('.data-field').val()), function(i, selectedOption) {
      container.find('.dropdown-container .dropdown-option[data-value="' + selectedOption + '"]').addClass('select')
    })
    if (selector.data('select-by-group')){
      $.each(container.find('.dropdown-group'), function(gi, group) {
        if ($(group).find('.dropdown-option').length === $(group).find('.dropdown-option.select').length) {
          $(group).addClass('select')
        }
      })
    }
  }

  function saveData(container) {
    var selectArray = []
    $.each(container.find('.dropdown-container .dropdown-option.select'), function(oi ,option){
      selectArray.push(option.dataset.value)
    })
    container.find('.data-field').val(JSON.stringify(selectArray))
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