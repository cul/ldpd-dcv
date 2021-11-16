/*****************
 * DCV.ProjModal *
 *****************/
import ColorBox from "../jquery.colorbox";

export function show (displayUrl, projectTitle){
  ColorBox.call($, {
    href: displayUrl,
    maxHeight:"90%",
    width:"90%",
    maxWidth:"1200px",
    opacity:".6",
    fixed:true,
    inline:true,
    preloading: false,
    close: '\uf00d',
    title: projectTitle,
    onClosed: function() {
        $(displayUrl).addClass('hidden');
    },
    onOpen: function() {
        $(displayUrl).removeClass('hidden');
    },
    onComplete: function() {
    	console.log("onComplete");
        $(displayUrl).removeClass('hidden');
        ColorBox.resize.call($, {});
    }
  });
  return false;
};

export default function(element) {
	return show($(element).attr('data-proj-more'), $(element).attr('data-proj-title'));
};
