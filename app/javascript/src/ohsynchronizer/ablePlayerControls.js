import PlayerControls from './playerControls';
import { secondsAsTimestamp } from './timeStamps';
export default class AblePlayerControls extends PlayerControls {

	player() {
		if ($("#audio").is(':visible')) return $("#audio-player")[0];
		else if ($("#video").is(':visible')) return $("#video-player")[0];
	}

	seekMinute(minute) {
		var offset = $('#sync-roll').val();
		this.player().currentTime = minute * 60 - offset;
	}

	seekTo(time) {
		this.player().currentTime = parseInt(time);
	}

	currentTime() {
		return this.player().currentTime;
	}

	duration() {
		return this.player().duration;
	}

	// Here we update the timestamp for the Tag Segment function for AblePlayer
	updateTimestamp() {
		var time = this.player().currentTime;
		$("#tag-timestamp").val(secondsAsTimestamp(time));
	}

	// Here we handle the keyword player controls for AblePlayer
	playerControls(button) {
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
}