import videojs from 'video.js';
import PlayerControls from './playerControls';
import { secondsAsTimestamp } from './timeStamps';

export default class VideoJsControls extends PlayerControls {
	videoPlayer = null;
	onReadyCallbacks = [];

	constructor() {
		super();

		const options = {
			controls: true,
			responsive: true,
			fluid: true,
			playbackRates: [0.5, 1, 1.5, 2],
			controlBar: {
				remainingTimeDisplay: false,
			}
		};

		let element = null;

		if ($("#audio").is(':visible')) {
			element = $("#audio audio")[0];
			options.poster = element.getAttribute('poster');
			// picture-in-picture doesn't apply to audio, so we won't show the button
			options.controlBar.pictureInPictureToggle = false;
		} else if ($("#video").is(':visible')) {
			element = $("#video video")[0];
		} else {
			console.error("No video or audio element found.");
		}

		element.classList.add('video-js', 'vjs-big-play-centered');

		this.videoPlayer = videojs(element, options);
		if (this.videoPlayer) {
			this.videoPlayer.on('ready', () => {
				this.onReadyCallbacks.forEach((callback) => callback());
			});
		}
	}

	onReady(callback) {
		this.onReadyCallbacks.push(callback);
	}

	player() {
		return this.videoPlayer;
	}

	seekMinute(minute) {
		var offset = $('#sync-roll').val();
		this.player().currentTime(minute * 60 - offset);
		if (!this.player().paused()) this.player().play();
	}

	seekTo(time) {
		this.player().currentTime(parseInt(time));
	}

	currentTime() {
		return this.player().currentTime();
	}

	duration() {
		return this.player().duration;
	}

	// Update the timestamp for the Tag Segment function for the player
	updateTimestamp() {
		var time = this.player().currentTime();
		$("#tag-timestamp").val(secondsAsTimestamp(time));
	}

	// Handle the keyword player controls for the player
	playerControls(button) {
		switch (button) {
			case "beginning":
				this.player().currentTime(0);
				break;

			case "backward":
				this.player().currentTime(this.player().currentTime() - 15);
				break;

			case "play":
				this.player().play();
				break;

			case "stop":
				this.player().pause();
				break;

			case "forward":
				this.player().currentTime(this.player().currentTime() + 15);
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
