// Use this to register outside-click directive on a Vue component
// eslint-disable-next-line max-len
// eg v-click-outside="{handler: 'handlerToTrigger', exclude: [refs to ignore on click (eg 'searchInput', 'searchInputBtn')]}"
// eslint-enable-next-line max-len

let handleOutsideClick;

export default {
  bind(el, binding, vnode) {
    const { handler, exclude } = binding.value;

    handleOutsideClick = (e) => {
      e.stopPropagation();

      let clickedOnExcludedEl = false;
      exclude.forEach(refName => {
        if (!clickedOnExcludedEl) {
          const excludedEl = vnode.context.$refs[refName];
          clickedOnExcludedEl = excludedEl?.contains(e.target);
        }
      });

      if (!el.contains(e.target) && !clickedOnExcludedEl) {
        vnode.context[handler]();
      }
    };

    document.addEventListener('click', handleOutsideClick);
    document.addEventListener('touchstart', handleOutsideClick);
  },
  unbind() {
    document.removeEventListener('click', handleOutsideClick);
    document.removeEventListener('touchstart', handleOutsideClick);
  }
};
