/* global */

(function () {
  const rtf = $('.rtf-view').toArray();
  for (let i = 0; i < rtf.length; i += 1) {
    const container = $(rtf[i]).find('table').toArray();

    for (let j = 0; j < container.length; j += 1) {
      const table = $(container[j]);
      if ($(table).parent().hasClass('table-wrapper')) return;

      $(table).wrap(`
        <div class="table-wrapper" style="overflow: auto; width: ${$($(rtf)[0]).parent().width()}px"></div>
      `);
    }
  }
}());
