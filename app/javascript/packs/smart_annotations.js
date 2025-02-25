const escapeHtml = (unsafe) => (
  unsafe.replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;')
);

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
          >${safeUserName}</a>`;
};

window.renderSmartAnnotations = (text) => (
  text.replace(/\[@([^~\]]+)~([0-9a-zA-Z]+)\]|\[#(.*?)~(rep_item|prj|exp|tsk)~([0-9a-zA-Z]+)\]/g, (match, userName, _userId, label, type) => {

    const tag = encodeURIComponent(match.slice(1, -1));

    if (userName) {
      return renderUserMention(tag, userName);
    }

    const safeLabel = escapeHtml(label);
    const safeType = escapeHtml(type);

    switch (type) {
      case 'rep_item':
        return `<a class="sa-link record-info-link" href="/sa?tag=${tag}"><span class="sa-type">INV</span>${safeLabel}</a>`;
      default:
        return `<a class="sa-link" href="/sa?tag=${tag}" target="_blank"><span class="sa-type">${safeType}</span>${safeLabel}</a>`;
    }
  })
);

window.renderElementSmartAnnotations = (element) => {
  element.innerHTML = window.renderSmartAnnotations(element.innerHTML);

  return true;
};

$(document).on('focus', '.user-tooltip', function () {
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
            ${escapeHtml(data.full_name)}
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
