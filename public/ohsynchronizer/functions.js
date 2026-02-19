export const timecodeRegEx = /(([\d]{2}:[\d]{2}:[\d]{2}.[\d]{3}\s-->\s[\d]{2}:[\d]{2}:[\d]{2}.[\d]{3}))+/;

/** General Functions **/

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
};

// Here is our error handling
export const errorHandler = function(e) {
	var error = '';
	error += '<div class="col-md-6"><i id="close" class="fa fa-times-circle-o close"></i><p class="error-bar"><i class="fa fa-exclamation-circle"></i> ' + e + '</p></div>';
	$('#messagesBar').append(error);
	$('html, body').animate({ scrollTop: 0 }, 'fast');

	closeButtons();
};

// Here we reload the page
export const clearBoxes = function() {
	if (confirm("This will clear the work in all areas.") == true) {
		location.reload(true);
	}
};

/* is this function intended to be set on the window, and replace the AblePlayer function?
   not apparently used in legacy module namespace
*/
const onYouTubeIframeAPIReady = function() {};
