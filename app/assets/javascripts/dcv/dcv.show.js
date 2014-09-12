window.DCV = window.DCV || {};
DCV.Show = {};
DCV.Show.FavoriteChildNavigation = {};

DCV.Show.FavoriteChildNavigation.previous = function(clickedElement){
	var currentFavoriteChildSequence = parseInt($('#favorite-child img').attr('data-sequence'));
	var highestChildSequence = DCV.Show.FavoriteChildNavigation.getHighestChildNumber();
	var childSequenceToGoTo = null;
	if (currentFavoriteChildSequence > 0) {
		childSequenceToGoTo = 0;
	} else {
		childSequenceToGoTo = highestChildSequence;
	}
	DCV.Show.FavoriteChildNavigation.goToChild(childSequenceToGoTo);
	$(clickedElement).blur();
	return false;
};

DCV.Show.FavoriteChildNavigation.next = function(clickedElement){
	var currentFavoriteChildSequence = parseInt($('#favorite-child img').attr('data-sequence'));
	var highestChildSequence = DCV.Show.FavoriteChildNavigation.getHighestChildNumber();
	var childSequenceToGoTo = null;
	if (currentFavoriteChildSequence < highestChildSequence) {
		childSequenceToGoTo = currentFavoriteChildSequence + 1;
	} else {
		childSequenceToGoTo = 0;
	}
	DCV.Show.FavoriteChildNavigation.goToChild(childSequenceToGoTo);
	$(clickedElement).blur();
	return false;
};

DCV.Show.FavoriteChildNavigation.getHighestChildNumber = function(){
	var maximum = null;

	$('#child_gallery a.document').each(function() {
		var value = parseInt($(this).attr('data-sequence'));
		maximum = (value > maximum) ? value : maximum;
	});

	return maximum;
};

DCV.Show.FavoriteChildNavigation.goToChild = function(sequenceNumber) {
	favoriteChild($('#child_gallery a.document[data-sequence="' + sequenceNumber + '"]')[0]);
};
