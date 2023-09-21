/* global iFrameModal  */
// General-purpose iframe modal. For closing the modal, you need will to take care of triggering
// the 'hide' event on the modal itself, example from inside the iframe:
// parent.document.getElementById('iFrameModal').dispatchEvent(new Event('hide'));

$(document).on('turbolinks:load', function() {
  window.iFrameModal = document.getElementById('iFrameModal');
  let iFrameModalFrame = document.getElementById('iFrameModalFrame');

  // Block from running when accessing page without defined iframe modal
  // (sign in, reset password, accept invitation, 2fa)
  if (!iFrameModalFrame || !iFrameModal) return;

  window.showIFrameModal = (url) => {
    iFrameModalFrame.setAttribute('src', url);
    iFrameModal.classList.remove('hidden');
    iFrameModal.dispatchEvent(new Event('shown'));
  };

  iFrameModal.addEventListener('hide', () => {
    iFrameModal.classList.add('hidden');
    iFrameModalFrame.removeAttribute('src');
    iFrameModal.dispatchEvent(new Event('hidden'));
  });

  iFrameModal.addEventListener('shown', () => {
    document.body.classList.add('overflow-hidden');
    document.body.classList.remove('overflow-auto');
  });

  iFrameModal.addEventListener('hidden', () => {
    document.body.classList.remove('overflow-hidden');
    document.body.classList.add('overflow-auto');
  });
});
