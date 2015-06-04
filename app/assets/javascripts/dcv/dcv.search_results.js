window.DCV = window.DCV || {};
DCV.SearchResults = {};

DCV.SearchResults.SearchMode = {
	GRID: 'grid',
	LIST: 'list',
	EXTENDED: 'extended'
}

DCV.SearchResults.DateGraphVisiblityState = {
	HIDE: 'hide',
	SHOW: 'show'
}

DCV.SearchResults.CookieNames = {};
DCV.SearchResults.CookieNames.searchMode = 'search_mode';
DCV.SearchResults.CookieNames.searchDateGraphVisiblity = 'search_date_graph_visibility';


DCV.SearchResults.configForLayout = {
	dcv: {
		defaultSearchMode: DCV.SearchResults.SearchMode.GRID,
		availableSearchModes: [DCV.SearchResults.SearchMode.GRID, DCV.SearchResults.SearchMode.LIST]
	},
	durst: {
		defaultSearchMode: DCV.SearchResults.SearchMode.GRID,
		availableSearchModes: [DCV.SearchResults.SearchMode.GRID, DCV.SearchResults.SearchMode.LIST, DCV.SearchResults.SearchMode.EXTENDED]
	},
	ifp: {
		defaultSearchMode: DCV.SearchResults.SearchMode.LIST,
		availableSearchModes: [DCV.SearchResults.SearchMode.LIST]
	},
	universityseminars: {
		defaultSearchMode: DCV.SearchResults.SearchMode.GRID,
		availableSearchModes: [DCV.SearchResults.SearchMode.GRID, DCV.SearchResults.SearchMode.LIST]
	},
	jay: {
		defaultSearchMode: DCV.SearchResults.SearchMode.GRID,
		availableSearchModes: [DCV.SearchResults.SearchMode.GRID, DCV.SearchResults.SearchMode.LIST]
	}
};

$(document).ready(function(){

	$('#list-mode').on('click', function() {
		DCV.SearchResults.setSearchMode(DCV.SearchResults.SearchMode.LIST);
	});
	$('#grid-mode').on('click', function() {
		DCV.SearchResults.setSearchMode(DCV.SearchResults.SearchMode.GRID);
	});
	$('#extended-search-mode, button.extended-search-mode').on('click', function() {
		DCV.SearchResults.setSearchMode(DCV.SearchResults.SearchMode.EXTENDED);
	});

	$('#return-to-results').on('click', function() {
		DCV.SearchResults.setSearchMode(DCV.SearchResults.getCurrentSearchMode());
	});
	$('#date-graph-toggle').on('click', function() {
		DCV.SearchResults.toggleSearchDateGraphVisibility();
	});

	//If we're on the search result page...
  if($('#search-results').length > 0) {

		var searchConfig = DCV.SearchResults.configForLayout[DCV.subsite_layout];

		if (searchConfig.availableSearchModes.length < 2) {
			//If there are fewer than 2 search modes, hide all search mode buttons (because there are no choices for the user to make)
			$('.result-type-button').hide();
		}

		var currentSearchMode = DCV.SearchResults.getCurrentSearchMode();
		if (currentSearchMode == null) {
			DCV.SearchResults.setSearchMode(searchConfig.defaultSearchMode);
		} else {
			DCV.SearchResults.setSearchMode(currentSearchMode);
		}

		var currentSearchDateGraphVisiblity = readCookie(DCV.subsite_layout + '_' + DCV.SearchResults.CookieNames.searchDateGraphVisiblity);
		if (currentSearchDateGraphVisiblity == null) {
			DCV.SearchResults.setSearchDateGraphVisibility(DCV.SearchResults.DateGraphVisiblityState.HIDE);
		} else {
			DCV.SearchResults.setSearchDateGraphVisibility(currentSearchDateGraphVisiblity);
		}
  }

});

DCV.SearchResults.getCurrentSearchMode = function(){
	return readCookie(DCV.subsite_layout + '_' + DCV.SearchResults.CookieNames.searchMode);
};



DCV.SearchResults.setSearchMode = function(searchMode) {

	$('.result-type-button').removeClass('btn-success').addClass('btn-default');

  if (searchMode == DCV.SearchResults.SearchMode.GRID) {
      $('#content .document').removeClass('col-sm-12').removeClass('list-view');
      $('#content .document').find('h3').addClass('ellipsis');
      $('#content .document .tombstone').removeClass('row');
      $('#content .document .thumbnail').removeClass('col-sm-2').removeClass('col-sm-1');
      $('#content .index-show-list-fields').addClass('hidden');
      $('#content .index-show-tombstone-fields').removeClass('hidden');
      $('#grid-mode').addClass('btn-success');
      createCookie(DCV.subsite_layout + '_' + DCV.SearchResults.CookieNames.searchMode, searchMode);
  } else if (searchMode == DCV.SearchResults.SearchMode.LIST) {
      $('#content .document').addClass('col-sm-12').addClass('list-view');
      $('#content .document').find('h3').removeClass('ellipsis');
			if(DCV.subsite_layout == 'ifp') {
				//IFP uses smaller thumbnails
				$('#content .document .thumbnail').addClass('col-sm-1');
			} else {
				$('#content .document .thumbnail').addClass('col-sm-2');
			}
			$('#content .index-show-tombstone-fields').addClass('hidden');
      $('#content .index-show-list-fields').removeClass('hidden');
      $('#list-mode').addClass('btn-success');
      createCookie(DCV.subsite_layout + '_' + DCV.SearchResults.CookieNames.searchMode, searchMode);
  } else if (searchMode == DCV.SearchResults.SearchMode.EXTENDED) {
			$('#search-results, .results-pagination, #appliedParams').addClass('hidden');
	    $('#extended-search-results').removeClass('hidden');
	    $('#extended-search-mode').addClass('btn-success');
			$('.extended-search-mode').addClass('hidden');
      $('#return-to-results').removeClass('hidden');
			//BUT DO NOT SET A COOKIE FOR EXTENDED MODE!  We don't want this mode to persist between page refreshes.
  } else {
    console.log('Invalid search mode: ' + searchMode);
  }

	//Undo EXTENDED mode changes, if necessary
	if (searchMode != DCV.SearchResults.SearchMode.EXTENDED) {
			$('#extended-search-mode').removeClass('btn-success');
	    $('#extended-search-results').addClass('hidden');
	    $('#search-results, .results-pagination, #appliedParams').removeClass('hidden');
			$('#return-to-results').addClass('hidden');
			$('.extended-search-mode').removeClass('hidden');
	}
}

DCV.SearchResults.setSearchDateGraphVisibility = function(dateGraphVisiblityState) {
  if (dateGraphVisiblityState == DCV.SearchResults.DateGraphVisiblityState.HIDE) {
    $('#search-results-date-graph').addClass('hidden');
    $('#date-graph-toggle').addClass('btn-default').removeClass('btn-success');
    createCookie(DCV.subsite_layout + '_' + DCV.SearchResults.CookieNames.searchDateGraphVisiblity, dateGraphVisiblityState);
  } else {
    $('#search-results-date-graph').removeClass('hidden');
    DCV.DateRangeGraphSelector.resizeCanvas();
    $('#date-graph-toggle').addClass('btn-success').removeClass('btn-default');
    createCookie(DCV.subsite_layout + '_' + DCV.SearchResults.CookieNames.searchDateGraphVisiblity, dateGraphVisiblityState);
  }
}

DCV.SearchResults.toggleSearchDateGraphVisibility = function() {
  if($('#search-results-date-graph').is(':hidden')) {
    DCV.SearchResults.setSearchDateGraphVisibility(DCV.SearchResults.DateGraphVisiblityState.SHOW);
  } else {
    DCV.SearchResults.setSearchDateGraphVisibility(DCV.SearchResults.DateGraphVisiblityState.HIDE);
  }
}
