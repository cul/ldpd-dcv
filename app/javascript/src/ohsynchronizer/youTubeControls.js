import PlayerControls from './playerControls';
import { secondsAsTimestamp } from './timeStamps';

export default class YouTubeControls extends PlayerControls {
	initializeControls(event) {
		this.ytplayer = event.target;
		var player = this;
		window.setInterval(function() { player.transcriptTimestamp();}, 500);

		// Capture the end timestamp of the YouTube video
		var time = this.ytplayer.getDuration();
		$('#endTime')[0].innerHTML = secondsAsTimestamp(time);

		this.transcriptTimestamp();
	}
	currentTime() {
		return this.ytplayer.getCurrentTime();
	}
	duration() {
		return this.ytplayer.getDuration();
	}
	seekMinute(minute) {
		var offset = $('#sync-roll').val();
		this.ytplayer.seekTo(minute * 60 - offset);
	}
	seekTo(time) {
		this.ytplayer.seekTo(time);
	}
	/** Index Segment Functions **/

	// Here we update the timestamp for the Tag Segment function for YouTube
	updateTimestamp() {
		var time = this.ytplayer.getCurrentTime();
		$("#tag-timestamp").val(secondsAsTimestamp(time));
	}
	// Here we handle the keyword player controls for YouTube
	playerControls(button) {
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
}
