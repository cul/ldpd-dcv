OHSynchronizer.YouTube = function(){
	OHSynchronizer.Player.call(this);
}

OHSynchronizer.YouTube.prototype = Object.create(OHSynchronizer.Player.prototype);
OHSynchronizer.YouTube.prototype.constructor = OHSynchronizer.YouTube;

OHSynchronizer.YouTube.prototype.currentTime = function() {
	return this.ytplayer.getCurrentTime();
}
OHSynchronizer.YouTube.prototype.duration = function() {
	return this.ytplayer.getDuration();
}
// Here we set up segment controls for the YouTube playback
OHSynchronizer.YouTube.prototype.initializeControls = function(event) {
	this.ytplayer = event.target;
	var player = this;
	window.setInterval(function() { player.transcriptTimestamp();}, 500);

	// Capture the end timestamp of the YouTube video
	var time = this.ytplayer.getDuration();
	$('#endTime')[0].innerHTML = OHSynchronizer.secondsAsTimestamp(time);

	this.transcriptTimestamp();
}

OHSynchronizer.YouTube.prototype.seekMinute = function(minute) {
	var offset = $('#sync-roll').val();
	this.ytplayer.seekTo(minute * 60 - offset);
}

OHSynchronizer.YouTube.prototype.seekTo = function(time) {
	this.ytplayer.seekTo(time);
}

/** Index Segment Functions **/

// Here we update the timestamp for the Tag Segment function for YouTube
OHSynchronizer.YouTube.prototype.updateTimestamp = function() {
	var player = "";

	var time = this.ytplayer.getCurrentTime();
	$("#tag-timestamp").val(OHSynchronizer.secondsAsTimestamp(time));
}

// Here we handle the keyword player controls for YouTube
OHSynchronizer.YouTube.prototype.playerControls = function(button) {
	switch(button) {
		case "beginning":
			this.ytplayer.seekTo(0);
			break;

		case "backward":
			this.ytplayer.seekTo(this.ytplayer.getCurrentTime() - 15);
			break;

		case "play":
			this.ytplayer.playVideo();
			break;

		case "stop":
			this.ytplayer.pauseVideo();
			break;

		case "forward":
			this.ytplayer.seekTo(this.ytplayer.getCurrentTime() + 15);
			break;

		case "update":
			this.updateTimestamp();
			break;

		case "seek":
			this.seekMinute(parseInt($("#sync-minute")[0].innerHTML));
			break;
		case "pause":
			this.updateTimestamp();
			this.ytplayer.pauseVideo();
			break;
		default:
			break;
	}
}
