import { uploadsuccess } from './events';
import { transcriptVTT } from './export';
import { closeButtons, errorHandler, timecodeRegEx } from './functions';
import PreviewWorker from './preview.worker.js';
import TranscriptWorker from './transcript.worker.js';
/** Transcript Sync Functions **/
export default class Transcript {
	constructor(id, options = {}){
		Object.call(this);
		this.contentDiv = $('#' + id);
		this.type = 'transcript';
		this.previewOnly = options.previewOnly;
	}

	dispose() {
		$('.transcript-word').off('click');
		$('.transcript-timestamp').off('click');
		$('.transcript-timestamp').off('dblclick');
	}

	fileReader(file, ext, playerControls) {
		var reader = new FileReader();
		var transcript = this;
		try {
			reader.onload = function(event) {
				var target = event.target.result;

				// If there's no A/V present, there is no transcript Syncing
				if (!($("#audio").is(':visible')) && !($("#video").is(':visible')) && $("#ytplayer")[0].innerHTML === '') {
					errorHandler(new Error("You must first upload an A/V file in order to sync a transcript."));
				} else {
				// VTT Parsing

					if (ext === 'vtt') {
						$("#finish-area").show();

						if (!(timecodeRegEx.test(target)) || target.indexOf("WEBVTT") !== 0){
							errorHandler(new Error("Not a valid VTT transcript file."));
						} else {
							if ($("#audio").is(':visible') || $("#video").is(':visible') || $("#ytplayer")[0].innerHTML != '') {
								if (!transcript.previewOnly) $("#sync-controls").show();
							}
							uploadsuccess(new CustomEvent("uploadsuccess", {detail: file}));
							closeButtons();
							// We'll break up the file line by line
							var text = target.split(/\r?\n|\r/);

							// We implement a Web Worker because larger transcript files will freeze the browser
							if (window.Worker) {
								var textWorker = (transcript.previewOnly) ? new PreviewWorker() : new TranscriptWorker();
								textWorker.postMessage(text);
								textWorker.onmessage = function(e) {
									$('#transcript')[0].innerHTML += e.data;
									transcript.setUpControls(playerControls);
								}
							}
						}
					}
					else errorHandler(new Error("Not a valid file extension."));
				}
			}
			return reader;
		} catch (e) { errorHandler(e); }
	}

	renderText(file, ext, playerControls) {
		var reader = this.fileReader(file, ext, playerControls);
		if (reader) reader.readAsText(file);
	}

	// Here we update Transcript Sync Current Mark
	static updateCurrentMark(tsSpan) {
		$(tsSpan).on('click', function(){
			var mark = $(this).html();
			mark = mark.replace("{", '');
			var num = mark.split(":");
			$("#sync-minute").html(num[0]);
		})
	}

	// Here we remove a Transcript Sync Marker
	static removeSyncMarker(tsSpan) {
		$(tsSpan).on('dblclick', function(){
			$(this).next(".transcript-clicked").removeClass('transcript-clicked');
			$(this).remove();
		});
	}

	static addTimestampMarker(element, minute) {
		const tsSpan = $('<span class="transcript-timestamp">{' + minute + ':00}&nbsp;</span>').insertBefore(element);
		Transcript.updateCurrentMark(tsSpan);
		Transcript.removeSyncMarker(tsSpan);
	}

	// Here we add a Sync Marker
	addSyncMarkerClickHandlers(playerControls) {
		$('.transcript-word').on('click', function(){
			var minute = parseInt($("#sync-minute").html());
			if (minute == 0) minute++;
			var marker = "{" + minute + ":00}";
			var regEx = new RegExp(marker);

			// If this word is already a sync marker, we don't make it another one
			if ($(this).hasClass('transcript-clicked')) {
				errorHandler(new Error("Word already associated with a transcript sync marker."));
			}
			else {
				// If a marker already exists for this minute, remove it and remove the word highlighting
				for (var sync of document.getElementsByClassName('transcript-timestamp')) {
					var mark = sync.innerText;
					if (regEx.test(mark)) {
						$(sync).next(".transcript-clicked").removeClass('transcript-clicked');
						sync.remove();
					}
				}

				$(this).addClass('transcript-clicked');
				Transcript.addTimestampMarker($(this), minute);

				// Increase the Sync Current Mark
				$("#sync-minute")[0].innerHTML = minute + 1;

				// If we are looping, we automatically jump forward
				if (playerControls.looping()) {
					$("#sync-minute").html(minute);
					Transcript.syncControl("forward", playerControls);
				}
			}
		});
	}

	preview(playerControls) {
		playerControls.loopMinute(-1);
		$("#transcript").hide();
		$("#sync-controls").hide();
		$("#transcript-preview").show();
		$("#export").addClass('hidden');
		$(".preview-button").addClass('hidden');
		$("#preview-close").removeClass('hidden');

		var transcript = this;
		var content = transcriptVTT(transcript).split(/\r?\n|\r/);
		if (window.Worker) {
			var textWorker = new PreviewWorker();
			textWorker.onmessage = function(e) {
				$("#transcript-preview").html(e.data);
				transcript.initPreviewControls();
			}
			textWorker.postMessage(content);
		}
	}

	setUpControls(playerControls) {
		$('.preview-minute').on('click', function(){
			var timestamp = $(this)[0].innerText.split('[');
			var minute = timestamp[1].split(':');
			playerControls.seekMinute(parseInt(minute[0]));
			playerControls.playerControls("play");
		});
		if (this.previewOnly) return;

		this.addSyncMarkerClickHandlers(playerControls);
	}

	exportVTT() {
		return transcriptVTT(this);
	}

	// Here we capture Transcript sync control clicks
	static syncControl(type, playerControls) {
		var minute = parseInt($("#sync-minute")[0].innerHTML);
		var offset = $('#sync-roll').val();

		switch(type) {
			// Hitting back/forward are offset by the roll interval
			case "back":
				minute -= 1;
				if (minute <= 0) $("#sync-minute")[0].innerHTML = 0;
				else $("#sync-minute").html(minute);

				playerControls.seekMinute(minute);
				break;

			case "forward":
				minute += 1;
				$("#sync-minute")[0].innerHTML = minute;

				playerControls.seekMinute(minute);
				break;

			case "loop":
				playerControls.transcriptLoop();
				break;

			default:
				break;
		}
	}
}