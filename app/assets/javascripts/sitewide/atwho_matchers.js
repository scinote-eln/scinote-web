// Trigger-boundary check for the '#' reference and '@' mention flags. The query itself is no
// longer typed into the host field (it's typed into the flyout's own search box - see
// smart_annotation_flyout.vue), so all this needs to answer is "was `flag` just typed at a valid
// boundary position, ending exactly at the caret".
var AtWhoMatchers = (function() {
  'use strict';

  // Both flags trigger anywhere, including mid-word or right after punctuation - there's no
  // boundary requirement beyond "the flag character is what was just typed".
  function isTriggerFlag(flag, subtext) {
    return !!subtext && subtext.charAt(subtext.length - 1) === flag;
  }

  return {
    isTriggerFlag: isTriggerFlag
  };
}());
