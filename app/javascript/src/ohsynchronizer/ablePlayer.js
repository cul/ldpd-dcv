OHSynchronizer.AblePlayer = function(){
	OHSynchronizer.Player.call(this);
};
OHSynchronizer.AblePlayer.prototype = Object.create(OHSynchronizer.Player.prototype);
OHSynchronizer.AblePlayer.prototype.constructor = OHSynchronizer.AblePlayer;

OHSynchronizer.AblePlayer.prototype.player = function() {
	if ($("#audio").is(':visible')) return $("#audio-player")[0];
	else if ($("#video").is(':visible')) return $("#video-player")[0];
}

OHSynchronizer.AblePlayer.prototype.seekMinute = function(minute) {
	var offset = $('#sync-roll').val();
	this.player().currentTime = minute * 60 - offset;
}

OHSynchronizer.AblePlayer.prototype.seekTo = function(time) {
	this.player().currentTime = parseInt(time);
}

OHSynchronizer.AblePlayer.prototype.currentTime = function() {
	return this.player().currentTime;
}

OHSynchronizer.AblePlayer.prototype.duration = function() {
	return this.player().duration;
}

// Here we update the timestamp for the Tag Segment function for AblePlayer
OHSynchronizer.AblePlayer.prototype.updateTimestamp = function() {
	var time = this.player().currentTime;
	$("#tag-timestamp").val(OHSynchronizer.secondsAsTimestamp(time));
}

// Here we handle the keyword player controls for AblePlayer
OHSynchronizer.AblePlayer.prototype.playerControls = function(button) {
	switch(button) {
		case "beginning":
			this.player().currentTime = 0;
			break;

		case "backward":
			this.player().currentTime -= 15;
			break;

		case "play":
			this.player().play();
			break;

		case "stop":
			this.player().pause();
			break;

		case "forward":
			this.player().currentTime += 15;
			break;

		case "update":
			this.updateTimestamp();
			break;

		case "seek":
			this.seekMinute(parseInt($("#sync-minute")[0].innerHTML));
			break;

		default:
			break;
	}
}
