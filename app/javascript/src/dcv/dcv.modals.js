import { getCurrentZoomUrl } from "./modals/zoomingImage";

const DcvModals = {
  titleFor: function(element) {
    const titleFunc = $(element).data('modal-title-func');
    if (titleFunc) {
      return DcvModals[titleFunc].call(self, element);
    }
    const titleDelegate =  $(element).data('modal-title-delegate');
    if (titleDelegate) return $(titleDelegate).html();
    return $(element).data('modal-title') || "";
  },
  downloadXmlTitle: function(element) {
    const downloadUrl = $(element).data('download-url');
    return '<a href="' + downloadUrl + '" data-no-turbolink="true"><span class="fa fa-download" aria-hidden="true"></span> Download XML</a>';
  },
  bodyFor: function(element) {
    const embedFunc = $(element).data('modal-embed-func');
    const displayUrl = (embedFunc) ? DcvModals[embedFunc].call(self, element) : $(element).data('display-url');
    if (displayUrl) {
      const fullscreen = ($(element).data('modal-fullscreen') == 'true') ? 'allowfullscreen' : '';
      return '<div class="embed-responsive  embed-responsive-16by9"><iframe class="embed-responsive-item" src="' + displayUrl + '" ' + fullscreen + '></iframe></div>';
    }
    const bodyDelegate = $(element).data('modal-body-delegate');
    if (bodyDelegate) return $(bodyDelegate).html();
    return $(element).data('modal-body');
  },
  feedbackEmbedUrl: (element) => ((window.CULh_feedback_url || 'https://feedback.cul.columbia.edu/feedback_submission/dlc') +
    '?submitted_from_page=' +
    encodeURIComponent(document.URL) +
    '&window_width=' +
    $(window).width() +
    '&window_height=' +
    $(window).height()
  ),
  getCurrentZoomUrl: getCurrentZoomUrl,
  needsEmbed: (element) => $(element).data('display-url') || $(element).data('modal-embed-func'),
  needsSize: (element) => $(element).data('modal-size'),
};

export default DcvModals;