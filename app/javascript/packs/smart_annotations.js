/* global I18n */

const SA_REGEX = /\[@([^~\]]+)~([0-9a-zA-Z]+)\]|\[#(.*?)~(rep_item|prj|exp|tsk)~([0-9a-zA-Z]+)\]/g;

const escapeHtml = (unsafe) => (
  unsafe.replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;')
);

const isInViewport = (element) => {
  const rect = element.getBoundingClientRect();
  const html = document.documentElement;

  return (
    rect.top >= 0 && rect.left >= 0
    && rect.bottom <= (window.innerHeight || html.clientHeight)
    && rect.right <= (window.innerWidth || html.clientWidth)
  );
};

const renderUserMention = (tag, userName) => {
  const safeUserName = escapeHtml(userName);

  return `<a
            role="button"
            class="user-tooltip"
            data-container="body"
            data-html="true"
            tabindex="0"
            data-trigger="manual"
            data-placement="auto"
            data-toggle="popover"
            data-content=""
            data-url="/sa/u?tag=${tag}"
          ><span class="sa-name"><span class="sci-loader-inline"></span></span></a>`;
};

window.renderSmartAnnotations = (text) => (
  text.replace(SA_REGEX, (match, userName, _userId, _label, type) => {
    const tag = encodeURIComponent(match.slice(1, -1));

    if (userName) {
      return renderUserMention(tag, userName);
    }

    switch (type) {
      case 'rep_item':
        return `<a class="sa-link record-info-link" href="/sa?tag=${tag}"><span class="sa-type"></span><span class="sa-name"><span class="sci-loader-inline"></span></span></a>`;
      default:
        return `<a class="sa-link" href="/sa?tag=${tag}" target="_blank"><span class="sa-type"></span><span class="sa-name"><span class="sci-loader-inline"></span></span></a>`;
    }
  })
);

async function fetchSmartAnnotationData(element) {
  const response = await fetch(`${element.getAttribute('href') || element.getAttribute('data-url')}&data=true`);

  const data = await response.json();

  element.querySelector('.sa-name').innerHTML = escapeHtml(data.name) || `(${I18n.t('general.private')})`;

  if (element.querySelector('.sa-type')) {
    element.querySelector('.sa-type').innerHTML = escapeHtml(data.type);
  }
}

window.renderElementSmartAnnotations = (element) => {
  if (!element.innerHTML.match(SA_REGEX)) return true;

  element.innerHTML = window.renderSmartAnnotations(element.innerHTML);

  // Schedule fetch of data for each annotation element when it scrolls into viewport
  element.querySelectorAll('.sa-link, .user-tooltip').forEach((el) => {
    if (isInViewport(el)) {
      fetchSmartAnnotationData(el);
      return;
    }

    const fetchFunction = () => {
      fetchSmartAnnotationData(el);
      window.removeEventListener('scroll', fetchFunction);
    };

    window.addEventListener('scroll', fetchFunction);
  });

  return true;
};

// using legacy jQuery style, as we need it for tooltips anyway
$(document).on('click', '.user-tooltip', function () {
  $.get($(this).data('url'), (data) => {
    const content = `<div class="user-name-popover-wrapper">
      <div class='col-xs-3'>
        <img
          class='avatar img-responsive'
          src='${data.avatar_url}'
          alt='thumb'>
      </div>
      <div class='col-xs-9 pl-3'>
        <div class='row'>
          <div class='col-xs-12 text-left font-bold'>
            ${escapeHtml(data.name)}
          </div>
        </div>
        <div class='row'>
          <div class='col-xs-12'>
            <p class='silver email'>${escapeHtml(data.email)}</p>
            <p>${data.info}</p>
          </div>
        </div>
      </div>
    </div>`;

    $(this).attr('data-content', content);
    $(this).popover('show');

    $(this).one('mouseout', function () { $(this).popover('hide'); });
  });
});
