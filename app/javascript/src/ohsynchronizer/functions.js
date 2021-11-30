/* Columbia University Library
	Project: Synchronizer Module
	File: script.js
	Description: Javascript functions providing file upload and display
	Authors: Ashley Pressley, Benjamin Armintor
	Date: 05/23/2018
	Version: 1.0
*/

export const onYouTubeIframeAPIReady = function() {}

export const timestampToDate = function(timestamp) {
	var parts = timestamp.split(/[:\.]/);
	var result = new Date();
	result.setHours(parts[0]);
	result.setMinutes(parts[1]);
	result.setSeconds(parts[2]);
	result.setMilliseconds(parts[3]);
	return result;
}

export const timestampAsSeconds = function(timestamp) {
	var parts = timestamp.split(/[:\.]/);
	var result = parseInt(parts[0]) * 3600;
	result += parseInt(parts[1]) * 60;
	result += parseInt(parts[2]);
	result += parseInt(parts[3])/1000;
	return result;
}

export const twoDigits = function(value, frac) {
	return Number(value).toLocaleString(undefined, {minimumIntegerDigits: 2, maximumFractionDigits: frac, minimumFractionDigits: frac});
}

export const secondsAsTimestamp = function(time, frac = 3) {
	var minutes = Math.floor(time / 60);
	var seconds = (time - minutes * 60).toFixed(3);
	var hours = Math.floor(minutes / 60);
	if (hours > 0) minutes = minutes - 60 * hours;
	return OHSynchronizer.twoDigits(hours, 0) + ":" + OHSynchronizer.twoDigits(minutes, 0) + ":" + OHSynchronizer.twoDigits(seconds, frac);
}






/** General Functions **/

// Here is our error handling
export const errorHandler = function(e) {
	var error = '';
	error += '<div class="col-md-6"><i id="close" class="fa fa-times-circle-o close"></i><p class="error-bar"><i class="fa fa-exclamation-circle"></i> ' + e + '</p></div>';
	$('#messagesBar').append(error);
	$('html, body').animate({ scrollTop: 0 }, 'fast');

	OHSynchronizer.Index.closeButtons();
}

// Here we reload the page
export const clearBoxes = function() {
	if (confirm("This will clear the work in all areas.") == true) {
		location.reload(true);
	}
}

// Here we remove items the user no longer wishes to see
// Includes deleting Segment Tags
export const closeButtons = function() {
	$('.close').on('click', function(){
		$(this).parent('div').fadeOut();
	});

	$('.tag-delete').on('click', function(){
		var panel = $(this).parents('div').get(2);
		panel.remove();
	});
}
