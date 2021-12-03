import { secondsAsTimestamp } from './timeStamps';
import Transcript from './transcript';
/** Player Functions **/
export default class PlayerControls {
	constructor() {
		this.loopingMinute = -1;
	}
	loopMinute(minute) {
		this.loopingMinute = minute;
	}
	looping() {
		return this.loopingMinute !== -1;
	}

	transcriptTimestamp() {
		var chime1 = $(".loop-boundary-chime")[0];
		var chime2 = $(".loop-mid-chime")[0];

		let player = null;
		if ($("#audio").is(':visible')) player = $("#audio-player")[0];
		else if ($("#video").is(':visible')) player = $("#video-player")[0];

		var time = this.currentTime();
		var offset = $('#sync-roll').val();

		// We only play chimes if we're on the transcript tab, and looping is active
		var synchingTranscript = $("#transcript").is(':visible');
		var loopingOnTranscript =  synchingTranscript && this.looping();
		if (Math.floor(time) % 60 == (60 - offset) && loopingOnTranscript) { chime1.play(); }
		if (Math.floor(time) % 60 == 0 && Math.floor(time) != 0 && loopingOnTranscript) { chime2.play(); }

		// If looping is active, we will jump back to a specific time should the the time be at the minute + offset
		if ((Math.floor(time) % 60 == offset || time === this.duration() ) && loopingOnTranscript) {
			$("#sync-minute")[0].innerHTML = parseInt($("#sync-minute")[0].innerHTML) + 1;
			Transcript.syncControl("back", this);
			this.playerControls("play");
		}

		var timestamp = secondsAsTimestamp(time, 0);
		$("#sync-time").html(timestamp);
		// If the user is working on an index segment, we need to watch the playhead
		$("#tag-playhead").val(timestamp);
	}

	transcriptLoop() {
		var minute = parseInt($("#sync-minute")[0].innerHTML);

		// We don't loop at the beginning of the A/V
		if (minute === 0) {  }
		else {
			// If looping is active we stop it
			if (this.looping()) {
				this.playerControls("pause");
				$('#sync-play').addClass('btn-outline-info');
				$('#sync-play').removeClass('btn-info');
				this.loopMinute(-1);
			}
			// If looping is not active we start it
			else {
				this.seekMinute(minute);
				this.playerControls("play");
				$('#sync-play').removeClass('btn-outline-info');
				$('#sync-play').addClass('btn-info');
				this.loopMinute(minute);
			}
		}
	}

	bindNavControls() {
		var controls = this;
		$('.tag-control-beginning').on('click', function(){ controls.playerControls('beginning') });
		$('.tag-control-backward').on('click', function(){ controls.playerControls('backward') });
		$('.tag-control-play').on('click', function(){ controls.playerControls('play') });
		$('.tag-control-stop').on('click', function(){ controls.playerControls('stop') });
		$('.tag-control-forward').on('click', function(){ controls.playerControls('forward') });
		$('.tag-control-update').on('click', function(){ controls.playerControls('update') });
	}

	dispose() {
		$('.preview-button').off('click'); // bound outside widget
		$('.tag-control-beginning').off('click');
		$('.tag-control-backward').off('click');
		$('.tag-control-play').off('click');
		$('.tag-control-stop').off('click');
		$('.tag-control-forward').off('click');
		$('.tag-control-update').off('click');
	}
}
