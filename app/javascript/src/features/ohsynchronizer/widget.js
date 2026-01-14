import SynchronizerIndex from './index';
import SynchronizerTranscript from './transcript';
import { mediaFromFile, mediaFromUrl, uploadedFile } from './import';

/* Columbia University Library
	Project: Synchronizer Module
	File: script.js
	Description: Javascript functions providing file upload and display
	Authors: Ashley Pressley, Benjamin Armintor
	Date: 05/23/2018
	Version: 1.0
*/

/** Global variables **/
// Here we embed the empty YouTube video player
// This must be presented before any function that can utilize it

export default class OHSynchronizer {
	static player(feature, options) {
		if (feature.url) {
			return mediaFromUrl(feature.url, feature);
		} else if (feature.fileId) {
			var fileInfo = uploadedFile(feature.fileId);
			return mediaFromFile(fileInfo[0], fileInfo[1]);
		} else if (feature.file) {
			return mediaFromFile(feature.file[0], feature.file[1]);
		}
	}

	constructor(config = {}) {
		if (!config.options) config.options = {};
		if (config.player) this.playerControls = OHSynchronizer.player(config.player, config.options);
		if (config.index) this.index = this.configIndex(config.index, config.options);
		if (config.transcript) this.transcript = this.configTranscript(config.transcript, config.options);
	}

	configWidget(widget, feature) {
		if (feature.fileId) {
			var fileInfo = uploadedFile(feature.fileId);
			widget?.renderText(fileInfo[0], fileInfo[1], this.playerControls);
		} else if (feature.url) {
			var xhr = new XMLHttpRequest();
			xhr.open('GET', feature.url, true);
			xhr.responseType = 'blob';
			const playerControls = this.playerControls;
			xhr.onload = function(e) {
				var blob = new Blob([xhr.response], {type: 'text/vtt'});
				widget.renderText(blob, 'vtt', playerControls);
			};
			xhr.send();
		}
		return widget;
	}

	configIndex(feature, options) {
		return  this.configWidget(new SynchronizerIndex(feature.id, options), feature);
	}

	configTranscript(feature, options) {
		return this.configWidget(new SynchronizerTranscript(feature.id, options), feature);
	}

	hideFinishingControls() {
		$('.session-controls > .btn').hide();
	}

	dispose() {
		// feature disposals
		if (this.playerControls) this.playerControls.dispose();
		if (this.index) this.index.dispose();
		if (this.transcript) this.transcript.dispose();
		// time monitor disposals
		$("#audio-player").off('timeupdate');
		$("#audio-player").off('durationchange');
		$("#video-player").off('timeupdate');
		$("#video-player").off('durationchange');
		// preview control disposals
		$('.preview-button').off('click');
		$('.preview-minute').off('click');
		$('.preview-segment').off('click');
	}
}

OHSynchronizer.errorHandler = function(e) {
  alert(e);
}
