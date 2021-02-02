$(function() {

  // quick hack to get openseadragon height to be viewport height
  $('#zoom-content').height($(window).height()-120);
  /* rand banner img */
  /* unused for now
  var $rbi = [];
  var $ielems = $('.thumbnail img'), icount = $ielems.length;
  $ielems.each(function() {
    $rbi.push($ielems.attr('src'));
    if (!--icount) {
      ix = Math.floor($rbi.length*Math.random())
      $('#site-banner-left').css('background-image','url('+$rbi[ix]+')');
    }
  });
  */
  /* scroll to top function */
  $('body').on('click', '.totop', function() {
    $('body,html').animate({ scrollTop: 0 }, 500, 'swing');
    return false;
  });
  $('body').on('click', '.tocontent', function() {
    $('body,html').animate({ scrollTop: $('#content').offset().top - $('#topnavbar').height() }, 500, 'swing');
    return false;
  });

  $('#search-navbar').find('.reset-btn').hover(function() {
      $('#appliedParams').find('.remove').addClass('btn-danger');
    }, function() {
      $('#appliedParams').find('.remove').removeClass('btn-danger');
  });
  $('#q').focus(function() {
    $('#search-navbar .input-group').css('box-shadow','0 0 3px #ccf');
  });
  $('#q').blur(function() {
    $('#search-navbar .input-group').css('box-shadow','none');
  });

  $('#show_file_assets_checkbox').on('change', function(){
    window.location = decodeURIComponent($(this).attr('data-new-location'));
  });
  $('#collapseDesc').on('show.bs.collapse', function(e){
    $(this).parent().find('i.more').addClass('glyphicon-chevron-down');
    $(this).parent().find('i.more').removeClass('glyphicon-chevron-right');
  })
  $('#collapseDesc').on('hide.bs.collapse', function(e){
    $(this).parent().find('i.more').removeClass('glyphicon-chevron-down');
    $(this).parent().find('i.more').addClass('glyphicon-chevron-right');
  })
  $('#toggle-metadata-control').on('click', function(e){
    $('#title-accordion').find('.accordion-toggle').trigger('click');
  });

  //Date Range Graph Setup
  //Activate date graph if cookie is set
  DCV.DateRangeGraphSelector.init();
  DCV.DateRangeSlider.init();

  // do fancy tooltips when data-toggle="tooltip" is set on el
  $('[data-toggle="tooltip"], [data-tt="tooltip"]').tooltip({container: 'body'});
});

//** CULTNBW START **/
  CULh_colorfg = '#000000'; // topnavbar foreground color. hex value. ex: #002B7F
  CULh_colorbg = '#444444'; // topnavbar background color. hex value. ex: #779BC3
  CULh_nobs = 1; // uncomment to NOT load our bootstrap javascript file and or use your own (v2.3.x required)
//** /CULTNBW END **/


/**************
 * Proj Modal *
 **************/

DCV.ProjModal = {};
DCV.ProjModal.show = function(displayUrl, downloadUrl){

  $.colorbox({
    href: displayUrl,
    maxHeight:"90%",
	width:"90%",
    maxWidth:"1200px",
    opacity:".6",
    fixed:true,
    inline:true,
    preloading: false,
    close: '\ue014',
    title: downloadUrl,
    onClosed: function() {
         $(displayUrl).addClass('hide');
    },
    onOpen: function() {
         $(displayUrl).removeClass('hide');
    },
    onComplete: function() {
            $.colorbox.resize();
    }
  });

  return false;
};


/**************
 * MODS Modal *
 **************/

DCV.ModsDownloadModal = {};
DCV.ModsDownloadModal.show = function(displayUrl, downloadUrl){

  $.colorbox({
    href: displayUrl,
    height:"90%",
    width:"90%",
    opacity:".6",
    fixed:true,
    iframe:true,
    preloading: false,
    close: '\ue014',
    title: '<a href="' + downloadUrl + '" data-no-turbolink="true"><span class="glyphicon glyphicon-download"></span> Download XML</a>'
  });

  return false;
};

/**************
 * Feedback Modal *
 **************/

DCV.FeedbackModal = {};
// see also https://pixabay.com/blog/posts/draggable-jquery-colorbox-52/
DCV.FeedbackModal.onComplete = function(){
    $('#cboxDrag').on({
        mousedown: function(e){
            var os = $('#colorbox').offset(),
                dx = e.pageX-os.left, dy = e.pageY-os.top;
            $(document).on('mousemove.drag', function(e){
                $('#colorbox').offset({ top: e.pageY-dy, left: e.pageX-dx } );
            });
        },
        mouseup: function(){ $(document).unbind('mousemove.drag'); $('#cboxDrag').blur(); }
    });
};
DCV.FeedbackModal.onLoad = function(){
  var cboxDrag = "<button id='cboxDrag' type='button'>&#xe068;</button>";
  $(cboxDrag).insertBefore($('#cboxClose'));
};
DCV.FeedbackModal.onClosed = function(){
  $('#cboxDrag').remove();
};
DCV.FeedbackModal.show = function(){

  var feedbackUrl = window.CULh_feedback_url || 'https://feedback.cul.columbia.edu/feedback_submission/dlc';

  $.colorbox({
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
    title: false,
    close: '\ue014',
    onLoad: DCV.FeedbackModal.onLoad,
    onComplete: DCV.FeedbackModal.onComplete,
    onClosed: DCV.FeedbackModal.onClosed
  });

  return false;
};

/******************
 * Citation Modal *
 ******************/

DCV.CitationDisplayModal = {};
DCV.CitationDisplayModal.show = function(citationDisplayUrl, modalLabel){

  $.colorbox({
    href: citationDisplayUrl,
    height:"90%",
    maxHeight:'300px',
    width:"90%",
    maxWidth:"1200px",
    opacity:".6",
    fixed:true,
    iframe:true,
    preloading: false,
    current:"{current} of {total}",
    close: '\ue014',
    title: modalLabel
  });

  return false;
};

/*********************
 * ZoomingImage Modal *
 *********************/

DCV.ZoomingImageModal = {};
DCV.ZoomingImageModal.show = function(){

  var zoomUrl = DCV.ZoomingImageModal.getCurrentZoomUrl();

  $.colorbox({
    href: zoomUrl,
    height:"90%",
    width:"90%",
    opacity:".6",
    fixed:true,
    iframe:true,
    preloading: false,
    close: '\ue014',
    current:"{current} of {total}"
  });

  return false;
};

DCV.ZoomingImageModal.openInNewWindow = function() {
  window.open(DCV.ZoomingImageModal.getCurrentZoomUrl());
  return false;
};

DCV.ZoomingImageModal.getCurrentZoomUrl = function() {
  var currentChild = $('#favorite-child img');
  var url = new URL(currentChild.attr('data-zoom-url'));
  url.searchParams.append('initial_page', currentChild.attr('data-sequence'))
  return url.toString();
}

/********************
 * CLIPBOARD HELPER *
 ********************/
DCV.Clipboard = {};
DCV.Clipboard.copyFromElement = function(ele) {
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

/***********
 * COOKIES *
 ***********/

function createCookie(name, value, days) {
    var expires;

    if (!days) {
      days = 2000;
    }

    var date = new Date();
    date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000));
    expires = "; expires=" + date.toGMTString();

    document.cookie = escape(name) + "=" + escape(value) + expires + "; path=/";
}

function readCookie(name) {
    var nameEQ = escape(name) + "=";
    var ca = document.cookie.split(';');
    for (var i = 0; i < ca.length; i++) {
        var c = ca[i];
        while (c.charAt(0) === ' ') c = c.substring(1, c.length);
        if (c.indexOf(nameEQ) === 0) return unescape(c.substring(nameEQ.length, c.length));
    }
    return null;
}

function eraseCookie(name) {
    createCookie(name, "", -1);
}


/***********
 * ON LOAD *
 ***********/

$(window).on('load', function() {
    if ( $('body').hasClass('blacklight-home-restricted') ) {
        var rinner = $('#content').find('.inner:first');
        var sidebar = $('#sidebar').find('.inner:first');
        if (sidebar.height() > rinner.height()) {
            rinner.height(sidebar.height());
        }
    }
});
