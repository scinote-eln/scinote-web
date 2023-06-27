function userAvatar(url, initials, title) {
  var avatar;
  if (url) {
    avatar = `<img src="${url}" class="rounded-full w-full h-full" />`;
  } else {
    avatar = `<div class="w-full h-full rounded-full border border-sn-light-grey  bg-sn-super-light-grey flex justify-center items-center">
                <span class="text-[.625rem] leading-3 font-normal">
                  ${initials}
                </span>
              </div>`;
  }

  return `<div class="relative w-6 h-6" title="${title}">${avatar}</div>`;
}
