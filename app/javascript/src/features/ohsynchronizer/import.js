import VideoJsControls from './videoJsControls';
import YouTubeControls from './youTubeControls';
import { hlssuccess, uploadsuccess } from './events';
import { closeButtons, errorHandler } from './functions';
import { secondsAsTimestamp } from './timeStamps';

// Here we ensure the extension is usable by the system
const allowedExts = [
	"txt",
	"vtt",
	"xml",
	"srt",
	"mp4",
	"webm",
	"m3u8",
	"ogg",
	"mp3"
];

const checkExt = function (ext) {
	return allowedExts.indexOf(ext);
}

/** Import Functions **/

// Here we accept locally uploaded files
export const uploadedFile = function (sender) {
	// Grab the files from the user's selection
	var input = $(sender)[0];
	for (var i = 0; i < input.files.length; i++) {
		var file = input.files[i];

		// Get file extension
		var name = file.name.split('.');
		var ext = name[name.length - 1].toLowerCase();

		if (checkExt(ext) > -1) return [file, ext];
		else errorHandler(new Error("Bad File - cannot load data from " + file.name));
	}
}

// Here we accept URL-based files
// This function is no longer utilized for non-AV files
export const mediaFromUrl = function (url, options = {}) {
	if (typeof options.type == 'undefined') { options.type = 'video'; } // default to video if type was not specified

	// Handle various types of URLs (e.g. HLS, progressive download, YouTube)
	var id = '';
	var lowerCaseUrl = url.toLowerCase();

	// Browsers won't load https resources if the surrounding page is http,
	// so we'll throw an error.
	if (location.protocol == 'https:' && lowerCaseUrl.indexOf('http://') > -1) {
		errorHandler(new Error("Due to browser security measures, you cannot load an http video resource from an https web page."));
		return;
	}

	// Determine what type of URL we're working with
	var lowerCaseUrl = url.toLowerCase();
	if (lowerCaseUrl.indexOf('playlist.m3u8') > -1) {
		return renderHLS(url);
	} else if (lowerCaseUrl.indexOf('manifest.mpd') > -1) {
		errorHandler(new Error("MPEG-Dash is not currently supported. Use HLS for streaming sources."));
	} else if (lowerCaseUrl.indexOf('youtube') > -1) {
		// Full YouTube URL
		var urlArr2 = url.split('=');
		return loadYouTube(urlArr2[urlArr2.length - 1]);
	} else if (lowerCaseUrl.indexOf('youtu.be') > -1) {
		// Short YouTube URL
		var urlArr2 = url.split('/');
		return loadYouTube(urlArr2[urlArr2.length - 1]);
	} else {
		// Fall back to progressive download http/https
		if (options.type == 'video' || options.type == 'audio') {
			return renderMediaURL(url, options);
		} else {
			errorHandler(new Error("This field only accepts audio and video file URLs."));
		}
	}
}

/** Rendering Functions **/
// Here we load HLS playlists
export const renderHLS = function (url) {
	var player = document.querySelector('video');
	const playerControls = new VideoJsControls();
	playerControls.onReady(() => {
		// Must set before video plays
		$("#audio-player audio").on('timeupdate', function () { playerControls.transcriptTimestamp() });
		$("#video-player video").on('timeupdate', function () { playerControls.transcriptTimestamp() });
	});
	playerControls.bindNavControls();

	$("#media-upload").hide();
	// show audio or video
	$("#audio").show();
	$("#video").show();
	// show segment controls
	$(".tag-add-segment").show();
	$("#finish-area").show();
	if ($('#transcript')[0] && $('#transcript')[0].innerHTML != '') { $("#sync-controls").show(); }
	hlssuccess(new CustomEvent("hlssuccess", { detail: url }));
	closeButtons();
	return playerControls;
}

export const renderMediaURL = function (url, options = { type: 'video' }) {
	var selector = '#' + options.type + '-player';
	const playerControls = new VideoJsControls();
	$(selector).on('timeupdate', function () { playerControls.transcriptTimestamp() });
	$(selector).attr('src', url);
	$(selector)[0].play();
	$("#media-upload").hide();
	if (options.type == 'video') {
		$("#audio").hide();
		$("#video").show();
	} else {
		$("#audio").show();
		$("#video").hide();
	}
	// show segment controls
	$(".tag-add-segment").show();
	$("#finish-area").show();
	if ($('#transcript')[0] && $('#transcript')[0].innerHTML != '') { $("#sync-controls").show(); }
	closeButtons();
	playerControls.bindNavControls();
	return playerControls;
}

// Here we play video files in the video control player
const renderVideo = function (file) {
	const playerControls = new VideoJsControls();
	var reader = new FileReader();
	try {
		reader.onload = function (event) {
			var target = event.target.result;
			var videoNode = document.querySelector('video');

			videoNode.src = target;
			$("#media-upload").hide();
			// hide audio
			$("#audio").hide();
			$("#video").show();
			$(".tag-add-segment").show();
			$("#finish-area").show();
			if ($('#transcript')[0].innerHTML != '') {
				$("#sync-controls").show();
			}
			uploadsuccess(new CustomEvent("uploadsuccess", { detail: file }));
			closeButtons();
			playerControls.bindNavControls();
		}
	}
	catch (e) {
		errorHandler(e);
		$("#media-upload").show();
		$("#video").hide();
		$("#audio").hide();
		$(".tag-add-segment").hide();
		$("#sync-controls").hide();
	}

	reader.readAsDataURL(file);
	$('#video-player').on('durationchange', function () {
		var time = this.duration;
		$('#endTime')[0].innerHTML = secondsAsTimestamp(time);
	});
	return playerControls;
}

// Here we load the YouTube video into the iFrame via its ID
const loadYouTube = function (id) {
	if ($('#transcript')[0].innerHTML != '') { $("#sync-controls").show(); }
	$("#finish-area").show();
	$(".tag-add-segment").show();
	$("#media-upload").hide();

	// Create the iFrame for the YouTube player with the requested video
	var iframe = document.createElement("iframe");
	iframe.setAttribute("id", "ytvideo");
	iframe.setAttribute("frameborder", "0");
	iframe.setAttribute("allowfullscreen", "0");
	iframe.setAttribute("src", "https://www.youtube.com/embed/" + id + "?rel=0&enablejsapi=1&autoplay=1");
	iframe.setAttribute("width", "100%");
	iframe.setAttribute("height", "400px");

	$('#ytplayer').html(iframe);
	playerControls = new YouTubeControls();
	new YT.Player('ytvideo', {
		events: {
			'onReady': function (event) {
				playerControls.initializeControls(event);
				playerControls.bindNavControls();
			}
		}
	});
	return playerControls;
}

// Here we play audio files in the audio control player
const renderAudio = function (file) {
	const playerControls = new VideoJsControls();
	var reader = new FileReader();
	try {
		reader.onload = function (event) {
			var target = event.target.result;
			var audioNode = document.querySelector('audio');

			audioNode.src = target;
			$("#media-upload").hide();
			$("#audio").show();
			$("#video").hide();
			$(".tag-add-segment").show();
			$("#finish-area").show();
			if ($('#transcript')[0].innerHTML != '') { $("#sync-controls").show(); }
			uploadsuccess(new CustomEvent("uploadsuccess", { detail: file }));
			closeButtons();
			playerControls.bindNavControls();
		}
	}
	catch (e) {
		errorHandler(e);
		$("#media-upload").show();
		$("#video").hide();
		$("#audio").hide();
		$(".tag-add-segment").hide();
		$("#sync-controls").hide();
	}

	reader.readAsDataURL(file);
	$('#audio-player').on('durationchange', function () {
		var time = this.duration;
		$('#endTime')[0].innerHTML = secondsAsTimestamp(time);
	});
	return playerControls;
}

// Here we determine what kind of file was uploaded
export const mediaFromFile = function (file, ext) {
	// List the information from the files
	// console.group("File Name: " + file.name);
	// console.log("File Size: " + parseInt(file.size / 1024, 10));
	// console.log("File Type: " + file.type);
	// console.log("Last Modified Date: " + new Date(file.lastModified));
	// console.log("ext: " + ext);
	// console.log("sender: " + sender);
	// console.groupEnd();

	// We can't depend upon the file.type (Chrome, IE, and Safari break)
	// Based upon the extension of the file, display its contents in specific locations
	switch (ext) {
		case "mp4":
		case "webm":
			return renderVideo(file);
		case "ogg":
		case "mp3":
			return renderAudio(file);
		default:
			errorHandler(new Error("Bad File - cannot display data."));
	}
}
