window.initTooltip = (element) => {
  $(element).tooltip({
    container: 'body',
    delay: { show: 300, hide: 150 },
    trigger: 'hover',
    placement: (_, source) => {
      const position = $(source).attr('data-tooltip-placement');
      return position || 'top';
    },
    template: `<div class="tooltip" role="tooltip"><div class="tooltip-arrow">
    </div><div class="tooltip-inner !max-w-[250px] text-left bg-black text-sn-white text-xs p-2"></div></div>`
  });
};

window.destroyTooltip = (element) => {
  $(element).tooltip('destroy');
};

$(document).on('turbolinks:load', function() {
  $(document).find('[data-render-tooltip]').each(function() {
    window.initTooltip(this);
  })
});
