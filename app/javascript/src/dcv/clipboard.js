/********************
 * CLIPBOARD HELPER *
 ********************/
const copyFromElement = function(ele) {
  if (!navigator.clipboard) {
    ele.disabled = true;
    return;
  }

  try {
      var copyValue = ele.getAttribute("data-copy");
      navigator.clipboard.writeText(copyValue);
      $(ele).tooltip({'toggle': 'tooltip', 'title': 'Copied to clipboard', 'trigger': 'focus', 'placement': 'bottom', 'selector': true});
      $(ele).tooltip('show');
  } catch (error) {
      console.error("copy failed", error);
  }
 };

export default copyFromElement;