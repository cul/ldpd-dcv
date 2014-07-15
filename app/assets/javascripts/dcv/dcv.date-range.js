/*********************
 * Date Range Slider *
 *********************/

DCV.DateRangeSlider = {};
DCV.DateRangeSlider.init = function() {
  //$("#sidebar-date-range-slider").slider({
  //  min: DCV.dateWidgetData['earliest_start_year'],
  //  max: DCV.dateWidgetData['latest_end_year'],
  //  step: 1,
  //  values: [DCV.dateWidgetData['earliest_start_year'], DCV.dateWidgetData['latest_end_year']],
  //  slide: function(event, ui) {
  //      for (var i = 0; i < ui.values.length; ++i) {
  //          $("#sidebar-date-range-selector input.sliderValue[data-index=" + i + "]").val(ui.values[i]);
  //      }
  //  }
  //});
  //$("#sidebar-date-range-selector input.sliderValue[data-index=0]").val(DCV.dateWidgetData['earliest_start_year']);
  //$("#sidebar-date-range-selector input.sliderValue[data-index=1]").val(DCV.dateWidgetData['latest_end_year']);
  //$("#sidebar-date-range-selector input.sliderValue").change(function() {
  //    var $this = $(this);
  //    $("#sidebar-date-range-slider").slider("values", $this.data("index"), $this.val());
  //});
  //$('#sidebar-date-range-selector').on('submit', function(){
  //  e.preventDefault();
  //  alert('submit');
  //  DCV.DateRangeSlider.filterBySelectedDateRange();
  //  return false;
  //});
  $('#sidebar-date-range-set-btn').on('click', function(){
    DCV.DateRangeSlider.filterBySelectedDateRange();
    return false;
  });
};
DCV.DateRangeSlider.filterBySelectedDateRange = function() {
  var newStartYearFilter = $("#sidebar-date-range-selector input.sliderValue[data-index=0]").val();
  var newEndYearFilter = $("#sidebar-date-range-selector input.sliderValue[data-index=1]").val();
  var redirecUrl = decodeURIComponent(DCV.newDateFilterTemplateUrl).replace('_start_year_', newStartYearFilter).replace('_end_year_', newEndYearFilter);
  window.location = redirecUrl;
};

/****************************
 * Date Range GraphSelector *
 ****************************/

DCV.DateRangeGraphSelector = {};
DCV.DateRangeGraphSelector.lastClickEvent = null;

DCV.DateRangeGraphSelector.dateCache = null;

DCV.DateRangeGraphSelector.init = function() {
  if ($('#date-range-widget').length > 0 && DCV.dateWidgetData != null) {
    $('#date-range-widget').html('<canvas id="date-range-canvas" width="1000" height="150"></canvas>');
    var canvasJQueryElement = $('#date-range-canvas');
    canvasJQueryElement.attr('data-original-width', canvasJQueryElement[0].width).attr('data-original-height', canvasJQueryElement[0].height);
    DCV.DateRangeGraphSelector.resizeCanvas();
    DCV.DateRangeGraphSelector.render();
    $(window).on('resize', DCV.DateRangeGraphSelector.resizeCanvas);
    canvasJQueryElement.on('mousedown', function(e1){
      var e1ParentOffset = $(this).offset();
      var canvasXLocation = e1.pageX - e1ParentOffset.left;
      var canvasYLocation = e1.pageY - e1ParentOffset.top;

      $('#date-range-canvas').attr('data-begin-drag', 'true');
      $('#date-range-canvas').attr('data-drag-start-x', canvasXLocation);
      $("#date-range-canvas").on('mousemove.daterange', function(e2){
      if($('#date-range-canvas').attr('data-begin-drag') == 'true') {

          var e2ParentOffset = $(this).offset();
          var canvasXDragLocation = e2.pageX - e2ParentOffset.left;
          var canvasYDragLocation = e2.pageY - e2ParentOffset.top;

          $('#date-range-canvas').attr('data-drag-end-x', canvasXDragLocation);
          DCV.DateRangeGraphSelector.render();
        }
      });
      $(window).on('mouseup.daterange', function(e){
        if ($('#date-range-canvas').attr('data-begin-drag') == 'true') {
          $('#date-range-canvas').attr('data-begin-drag', 'false');
          $(window).off('.daterange'); //Remove .daterange listeners so that we're not constantly listening for mousemove and mouseup events
          //And redirect to the correct date range selection
          var newStartYearFilter = $('#date-range-canvas').attr('data-new-start-year-filter');
          var newEndYearFilter = $('#date-range-canvas').attr('data-new-end-year-filter');
          if (newStartYearFilter != 'NaN' && newStartYearFilter != 'NaN') {
            var redirecUrl = decodeURIComponent(DCV.newDateFilterTemplateUrl).replace('_start_year_', newStartYearFilter).replace('_end_year_', newEndYearFilter);
            DCV.DateRangeGraphSelector.clearSelectedRegionIndicator();
            window.location = redirecUrl;
          }
        }
      });
    });
  }
};

DCV.DateRangeGraphSelector.clearSelectedRegionIndicator = function() {
  var newStartYearFilter = $('#date-range-canvas').removeAttr('data-drag-start-x');
  var newEndYearFilter = $('#date-range-canvas').removeAttr('data-drag-end-x');
  DCV.DateRangeGraphSelector.render();
};

DCV.DateRangeGraphSelector.resizeCanvas = function() {
  // Make sure that actual canvas dimensions are equal to the current size
  // so that we don't get anti-aliased rescaling.  This will look sharper.

  var c = document.getElementById('date-range-canvas');
  var aspectRatio = parseInt($(c).attr('data-original-width'))/parseInt($(c).attr('data-original-height'));
  var canvasWidth = $(c).width();
  var canvasHeight = canvasWidth/aspectRatio;
  $(c).height(canvasHeight);

  c.width = canvasWidth;
  c.height = canvasHeight;

  DCV.DateRangeGraphSelector.render();
};

DCV.DateRangeGraphSelector.render = function() {

  var c = document.getElementById('date-range-canvas');

  var ctx = c.getContext('2d');

  ctx.clearRect ( 0 , 0 , c.width , c.height ); //clear canvas

  var segmentColors = ['#333', '#666'];

  ctx.lineWidth   = 1;
  ctx.strokeStyle = '#000';
  ctx.fillStyle   = '#000';

  // DCV.dateWidgetData is declared in-page, generated server-side.
  var earliestStartYear = DCV.dateWidgetData['earliest_start_year'];
  var latestEndYear = DCV.dateWidgetData['latest_end_year'];
  var segments = DCV.dateWidgetData['segments'];
  var yearsPerSegment = DCV.dateWidgetData['years_per_segment'];
  var highestSegmentCountValue = DCV.dateWidgetData['highest_segment_count_value'];

  var numSegments = segments.length;

  var padding = c.width/15;
  var segmentWidth = (c.width-padding*2)/numSegments;

  //Draw bounding box
  for(var i = 0; i < numSegments; i++) {

    //Time dividing lines
    ctx.strokeStyle = '#222';
    ctx.beginPath();
    ctx.moveTo(padding+i*segmentWidth, 0);
    ctx.lineTo(padding+i*segmentWidth, c.height);
    ctx.stroke();

    if (i == numSegments-1) {
      ctx.beginPath();
      ctx.moveTo(padding+(i+1)*segmentWidth, 0);
      ctx.lineTo(padding+(i+1)*segmentWidth, c.height);
      ctx.stroke();
    }

    //Segment blocks
    var segment = segments[i];
    ctx.fillStyle = segmentColors[i%segmentColors.length];
    var proportionalHeight = (segment['count']/(highestSegmentCountValue));

    //Post-processing to move values toward the center, making it look better
    if (proportionalHeight > 0) {
      var centerWeighting = .1;
      proportionalHeight = proportionalHeight+(centerWeighting*(.5-proportionalHeight));
    }
    ctx.fillRect(  padding+i*segmentWidth, c.height, segmentWidth, -c.height*proportionalHeight);

  }

  // Render text separately so that it's always on top of the bars

  var dateMarkersToRender = [0, .25, .50, .75]; // End is always makred
  var dateMarkerCounter = 0;

  for(var i = 0; i < numSegments; i++) {

    var segment = segments[i];
    if (i/numSegments >= dateMarkersToRender[dateMarkerCounter]) {

      dateMarkerCounter++;

      var textYOffset = c.height/7;
      var fontSize = c.height/8;
      var textXOffset = fontSize/6;

      ctx.fillStyle = "#000";
      ctx.font = fontSize + "px 'Helvetica Neue'";
      ctx.fillText(segment['start'], textXOffset+padding+i*segmentWidth-1, textYOffset-1);
      ctx.fillText(segment['start'], textXOffset+padding+i*segmentWidth+1, textYOffset+1);
      ctx.fillStyle = "#ddd";
      ctx.fillText(segment['start'], textXOffset+padding+i*segmentWidth, textYOffset);

    }

    if (i == numSegments-1) {
      ctx.fillText(segment['end'], textXOffset+padding+(i+1)*segmentWidth, textYOffset);
    }
  }

  //Overlay with drag
  var overlayXStart = parseInt($('#date-range-canvas').attr('data-drag-start-x'));
  var overlayXEnd = parseInt($('#date-range-canvas').attr('data-drag-end-x'));

  //Ignore accidental clicks
  if (overlayXStart == overlayXEnd) {
    $('#date-range-canvas').attr('data-new-start-year-filter', 'NaN');
    $('#date-range-canvas').attr('data-new-end-year-filter', 'NaN');
  } else {

    if(overlayXStart < overlayXEnd) {
      var startOfPixelRange = overlayXStart;
      var endOfPixelRange = overlayXEnd;
    } else {
      var startOfPixelRange = overlayXEnd;
      var endOfPixelRange = overlayXStart;
    }

    //Apply padding corrections
    startOfPixelRange -= padding;
    endOfPixelRange -= padding;

    var fullPixelRange = segmentWidth*numSegments;

    var dateRangeInYears = numSegments*yearsPerSegment;
    var newStartYearFilter = Math.round((startOfPixelRange/fullPixelRange)*dateRangeInYears)+earliestStartYear;
    var newEndYearFilter = Math.round((endOfPixelRange/fullPixelRange)*dateRangeInYears)+earliestStartYear;

    $('#date-range-canvas').attr('data-new-start-year-filter', newStartYearFilter);
    $('#date-range-canvas').attr('data-new-end-year-filter', newEndYearFilter);

    ctx.globalAlpha=0.5;
    ctx.fillRect(  overlayXStart, 0, overlayXEnd-overlayXStart, c.height);
    ctx.globalAlpha=1.0;
  }

};
