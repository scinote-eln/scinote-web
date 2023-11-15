// Use this to register outside-click directive on a Vue component
// eslint-disable-next-line max-len
// eg v-click-outside="{handler: 'handlerToTrigger', exclude: [refs to ignore on click (eg 'searchInput', 'searchInputBtn')]}"
// eslint-enable-next-line max-len

export default {
  bind(el, binding, vnode) {
    el._vueClickOutside_ = (e) => {
      let clickedOnExcludedEl = false;
      const { exclude } = binding.value;
      exclude.forEach(refName => {
        if (!clickedOnExcludedEl) {
          const excludedEl = vnode.context.$refs[refName];
          if (!excludedEl) return;

          clickedOnExcludedEl = (excludedEl._isVue ? excludedEl.$el : excludedEl).contains(e.target);
        }
      });

      if (!el.contains(e.target) && !clickedOnExcludedEl) {
        const { handler } = binding.value;
        vnode.context[handler]();
      }
    };

    document.addEventListener('click', el._vueClickOutside_);
    document.addEventListener('touchstart', el._vueClickOutside_);
  },
  unbind(el) {
    document.removeEventListener('click', el._vueClickOutside_);
    document.removeEventListener('touchstart', el._vueClickOutside_);
    el._vueClickOutside_ = null;
  }
};
