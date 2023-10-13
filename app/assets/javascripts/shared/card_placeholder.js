const loadPlaceHolder = function($cardsWrapper, $placeholderTemplate, placeholder, options = { gridGap: 25, rowsPerCard: 4, minPlaceholderCardHeight: 50 }) {
  const { gridGap, rowsPerCard, minPlaceholderCardHeight } = options;
  const windowHeight = window.innerHeight;
  const placeholderHTML = $placeholderTemplate.html();
  const tableHeader = $cardsWrapper.find('.table-header');
  let cardsWrapperBottom = $cardsWrapper.get(0).getBoundingClientRect().bottom;

  $(placeholderHTML).insertAfter(tableHeader);
  let cellCounter = 1;
  let totalCellCount = -Infinity;

  let placeholderCardHeight = Math.max($cardsWrapper.find(placeholder).outerHeight(), minPlaceholderCardHeight);

  if ($cardsWrapper.hasClass('list')) {
    placeholderCardHeight = parseInt(window.getComputedStyle($cardsWrapper.get(0))
      .getPropertyValue('grid-template-rows').split(' ')[0], 0);
  }

  while (cardsWrapperBottom < windowHeight) {
    $(placeholderHTML).insertAfter(tableHeader);
    cardsWrapperBottom = $cardsWrapper.get(0).getBoundingClientRect().bottom;
    const columnsCount = window.getComputedStyle($cardsWrapper.get(0))
      .getPropertyValue('grid-template-columns').split(' ').length;
    const rowsCount = window.getComputedStyle($cardsWrapper.get(0))
      .getPropertyValue('grid-template-rows').split(' ').length / rowsPerCard;
    totalCellCount = columnsCount * rowsCount;
    cellCounter += 1;
    if ($cardsWrapper.hasClass('list')
        && cardsWrapperBottom + placeholderCardHeight >= windowHeight) {
      break;
    } else if (cardsWrapperBottom + placeholderCardHeight + gridGap >= windowHeight
                && cellCounter >= totalCellCount) {
      break;
    }
  }
};

