const FOCUS_CLASSES = [
  'focus:outline-none',
  'focus-visible:outline',
  'focus-visible:outline-4',
  'focus-visible:outline-sn-science-blue-hover'
];

const managed = new WeakMap();

function onKeydown(e) {
  if (e.key !== 'Enter' && e.key !== ' ') return;

  e.preventDefault();
  if (!e.repeat) e.currentTarget.click();
}

function enable(el) {
  if (!managed.has(el)) {
    managed.set(el, { tabindex: !el.hasAttribute('tabindex'), role: !el.hasAttribute('role') });
    el.addEventListener('keydown', onKeydown);
  }

  const own = managed.get(el);
  if (own.tabindex) el.setAttribute('tabindex', '0');
  if (own.role) el.setAttribute('role', 'button');
  el.classList.add(...FOCUS_CLASSES);
}

function disable(el) {
  const own = managed.get(el);
  if (!own) return;

  el.removeEventListener('keydown', onKeydown);
  if (own.tabindex) el.removeAttribute('tabindex');
  if (own.role) el.removeAttribute('role');
  el.classList.remove(...FOCUS_CLASSES);
  managed.delete(el);
}

function sync(el, binding) {
  if (binding.value === false) {
    disable(el);
  } else {
    enable(el);
  }
}

export default {
  mounted: sync,
  updated: sync,
  unmounted: disable
};
