import setUpDownloadButton from './downloadsButton';
import setUpChildViewer from './childViewer';
import { dateWidgetReady } from './dcv.date-range';
import { mapReady } from './dcv.map';
import { searchResultsReady } from './dcv.search_results';
import { synchronizerReady } from './dcv.synchronizer';
/************
 * ON READY *
 ************/

const searchSetUp = function() {
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
    $(this).parent().find('i.more').addClass('fa-angle-down');
    $(this).parent().find('i.more').removeClass('fa-angle-right');
  })
  $('#collapseDesc').on('hide.bs.collapse', function(e){
    $(this).parent().find('i.more').removeClass('fa-angle-down');
    $(this).parent().find('i.more').addClass('fa-angle-right');
  })
  $('#toggle-metadata-control').on('click', function(e){
    $('#title-accordion').find('.accordion-toggle').trigger('click');
  });

  // do fancy tooltips when data-toggle="tooltip" is set on el
  $('[data-toggle="tooltip"], [data-tt="tooltip"]').tooltip({
      boundary: 'window',
      close: function () {$(".ui-helper-hidden-accessible").remove(); }
  });
};

const contentNoShorterThanSidebar = function() {
    if ( $('body').hasClass('blacklight-home-restricted') ) {
        var rinner = $('#content').find('.inner:first');
        var sidebar = $('#sidebar').find('.inner:first');
        if (sidebar.height() > rinner.height()) {
            rinner.height(sidebar.height());
        }
    }
};

export default [
  searchSetUp,
  dateWidgetReady,
  searchResultsReady,
  contentNoShorterThanSidebar,
  setUpChildViewer,
  setUpDownloadButton,
  mapReady,
  synchronizerReady
];
