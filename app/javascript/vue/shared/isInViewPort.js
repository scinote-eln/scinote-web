export default function isInViewPort(el) {
  if (!el) return;

  const rect = el.getBoundingClientRect();

  return (
    rect.top >= 0 &&
    rect.left >= 0 &&
    rect.bottom <=
      (window.innerHeight ||
        document.documentElement.clientHeight) &&
    rect.right <=
      (window.innerWidth ||
        document.documentElement.clientWidth)
  );
}
