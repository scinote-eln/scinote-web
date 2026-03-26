// AI generated - GPT-5.2

import escapeHtml from "./escape_html.js";

export default text => {
  const str = text == null ? "" : String(text);
  if (!/https?:\/\//.test(str)) return escapeHtml(str);

  const urlRegex = /(https?:\/\/[^\s<]+)/g;
  let out = "";
  let lastIndex = 0;
  let match;

  while ((match = urlRegex.exec(str))) {
    const raw = match[0];
    const start = match.index;

    out += escapeHtml(str.slice(lastIndex, start));

    const url = raw.replace(/[)\].,!?;:]+$/, "");
    const safeUrl = escapeHtml(url);
    out += `<a href="${safeUrl}" target="_blank" rel="noopener noreferrer">${safeUrl}</a>${escapeHtml(
      raw.slice(url.length)
    )}`;

    lastIndex = start + raw.length;
  }

  out += escapeHtml(str.slice(lastIndex));
  return out;
};
