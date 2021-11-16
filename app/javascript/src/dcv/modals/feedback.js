/*********************
 * DCV.FeedbackModal *
 *********************/
import ColorBox from "../jquery.colorbox";

export default function(){

  var feedbackUrl = window.CULh_feedback_url || 'https://feedback.cul.columbia.edu/feedback_submission/dlc';

  ColorBox.call($, {
    href: feedbackUrl + '?submitted_from_page=' + encodeURIComponent(document.URL) + '&window_width=' + $(window).width() + '&window_height=' + $(window).height(),
    className: 'cul-no-colorbox-title-bar',
    height:"478px",
    width:"700px",
    maxHeight:"90%",
    maxWidth:"90%",
    opacity:".6",
    fixed:true,
    iframe:true,
    preloading: false,
    current: false,
    close: '\uf00d',
    title: false
  });

  return false;
};