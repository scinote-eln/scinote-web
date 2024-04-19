export default {
  mounted() {
    this.initTooltips();
  },
  methods: {
    initTooltips() {
      const selector = '[data-render-tooltip]';
      $(this.$el).find(selector).each(() => {
        $(this).tooltip({
          container: 'body',
          delay: { show: 300, hide: 15000 },
          trigger: 'hover',
          placement: (_, source) => {
            const position = $(source).attr('data-tooltip-placement');
            return position || 'top';
          },
          template: `<div class="tooltip" role="tooltip"><div class="tooltip-arrow">
          </div><div class="tooltip-inner !max-w-[250px] text-left bg-black text-sn-white text-xs p-2"></div></div>`
        });
      });
    }
  },
  beforeDestroy() {
    $(this.$el).find('[data-render-tooltip]').tooltip('destroy');
  }
};
