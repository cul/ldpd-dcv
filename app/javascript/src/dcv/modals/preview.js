import ColorBox from "../jquery.colorbox";
export const show = function(displayUrl, title){
  ColorBox.call($, {
    href: displayUrl,
    maxHeight:"80%",
    maxWidth:"80%",
    opacity:".3",
    fixed:true,
    preloading: false,
    title: title
  });
  return false;
};

export default function(element) {
  var url = $(element).attr('href');
  var title = $(element).attr('data-title');
  return show(url, title);
};

