import { errorHandler } from './functions';
import { secondsAsTimestamp, timestampAsSeconds } from './timeStamps';

// Here we activate the minute sync markers created for previewing transcript
const addPreviewMinutes = function(playerControls) {
	$('.preview-minute').on('click', function(){
		var timestamp = $(this)[0].innerText.split('[');
		var minute = timestamp[1].split(':');
		playerControls.seekMinute(parseInt(minute[0]));
	});
}

// Here we activate the index segment buttons to for playing index segments during preview
const addPreviewSegments = function(playerControls) {
	$('.preview-segment').on('click', function(){
		const timestamp = $(this).parent().parent().parent().attr("id");
		playerControls.seekTo(timestampAsSeconds(timestamp));
		playerControls.playerControls("play");
	});
}


// Here we prepare transcript data for VTT files
export const transcriptVTT = function(_widget) {
	var minute = '';
	var metadata = $('#interview-metadata')[0].innerHTML.replace(/<br>/g, '\n');
	var content = $('#transcript')[0].innerHTML;

	// Need to find the first minute marker, because the first chunk of transcript is 0 to that minute
	minute = content.substring(content.indexOf("{") + 1, content.indexOf("}"));
	minute = minute.substring(0, minute.indexOf(':'));
	minute = (parseInt(minute) < 10) ? '0' + minute : minute;

	if (minute == '') {
		errorHandler(new Error("You must add at least one sync marker in order to prepare a transcript."));
		return false;
	}
	else {
		// Replace our temporary content with the real data for the export
		content = (metadata != '') ? 'WEBVTT\n\nNOTE\n' + metadata + '\n\n' : 'WEBVTT\n\n';
		content += '\n00:00:00.000 --> 00:' + minute + ':00.000\n';
		content += $('#transcript')[0].innerHTML.replace(/<\/span>/g, '').replace(/<span class="transcript-word">/g, '').replace(/&nbsp;/g, ' ').replace(/<span class="transcript-word transcript-clicked">/g, '');

		// This will help us find the rest of the minutes, as they are marked appropriately
		while (/([0-9]:00})+/.test(content)) {
			var currMin = 0;
			var currHour = 0;
			var newMin = 0;
			var newHour = 0;

			minute = content.substring(content.indexOf("{") + 1, content.indexOf("}"));
			minute = minute.substring(0, minute.indexOf(':'));
			currMin = parseInt(minute);
			newMin = currMin + 1;

			currHour = parseInt(minute / 60);
			currMin -= (currHour * 60);
			newHour = parseInt(newMin / 60);
			newMin -= (newHour * 60);

			content = content.replace(
				'<span class="transcript-timestamp">{' + minute + ':00} ',
				'\n\n' +
				(currHour < 10 ? '0' + currHour : currHour) + ':' + (currMin < 10 ? '0' + currMin : currMin) + ':00.000' +
				' --> ' +
				(newHour < 10 ? '0' + newHour : newHour) + ':' + (newMin < 10 ? '0' + newMin : newMin) + ':00.000' +
				'\n'
			);
		}

		return content;
	}
}

// Here we prepare index data for VTT files with jquery
const indexSegmentData = function(widget, duration) {
	var metadata = $('#interview-metadata')[0].innerHTML.replace(/<br>/g, '\n');
	var content = (metadata != '') ? 'WEBVTT\n\nNOTE\n' + metadata + '\n\n' : 'WEBVTT\n\n';
	var endProxy = {startTime : secondsAsTimestamp(duration)};
	// We'll break up the text by segments
	var segments = $(widget.indexDiv).find('.segment-panel').map(function(index, div){
		return {
			startTime: $(div).attr('id'),
			title: $(div).find(".tag-title").text(),
			keywords: $(div).find(".tag-keywords").text(),
			subjects: $(div).find(".tag-subjects").text(),
			description: $(div).find(".tag-segment-synopsis").text(),
			partialTranscript: $(div).find(".tag-partial-transcript").text(),
		}
	});
	segments.map(function(index, segment) {
		segment.endTime = (segments[index + 1] || endProxy).startTime;
	});

	return segments;
}
// Here we prepare index data for VTT files
export const indexVTT = function(widget) {
	var metadata = $('#interview-metadata')[0].innerHTML.replace(/<br>/g, '\n');
	var content = (metadata != '') ? 'WEBVTT\n\nNOTE\n' + metadata + '\n\n' : 'WEBVTT\n\n';

	// We'll break up the text by segments
	var segments = indexSegmentData(widget, widget.duration);

	segments.each(function(index, segment) {

		content += segment.startTime + ' --> ' + segment.endTime + '\n{\n';
		content += '  "title": "' + segment.title.replace(/"/g, '\\"') + '",\n';
		content += '  "partial_transcript": "' + segment.partialTranscript.replace(/"/g, '\\"') + '",\n';
		content += '  "description": "' + segment.description.replace(/"/g, '\\"') + '",\n';
		content += '  "keywords": "' + segment.keywords.replace(/"/g, '\\"') + '",\n';
		content += '  "subjects": "' + segment.subjects.replace(/"/g, '\\"') + '"\n';
		content += '}\n\n\n';
	});

	return content;
}

// Here we use VTT-esque data to preview the end result
export const previewWork = function(type, playerControls) {
	// Make sure looping isn't running, we'll stop the A/V media and return the playhead to the beginning
	playerControls.loopMinute(-1);
	playerControls.playerControls("beginning");
	playerControls.playerControls("stop");

	if ($('#media-upload').visible){
		errorHandler(new Error("You must first upload media in order to preview."));
	} else if (type.toLowerCase() == "transcript" && $('#transcript')[0].innerHTML != '') {
		// The current open work needs to be hidden to prevent editing while previewing
		$("#transcript").hide();
		$("#sync-controls").hide();
		$("#transcript-preview").show();
		$("#export").addClass('hidden');
		$(".preview-button").addClass('hidden');
		$("#preview-close").removeClass('hidden');

		var content = transcriptVTT();
		$("#transcript-preview")[0].innerHTML = "<p>";

		// We need to parse the VTT-ified transcript data so that it is "previewable"
		var text = content.split(/\r?\n|\r/);
		var first = false;
		var timestampRegex = /^(\d{2}):(\d{2}):\d{2}\..+/;

		for (var i = 0; i < text.length; i++) {
			if (/(([0-9]{2}:[0-9]{2}:[0-9]{2}.[0-9]{3}\s-->\s[0-9]{2}:[0-9]{2}:[0-9]{2}.[0-9]{3}))+/.test(text[i])) {
				if (!first) first = true;
				//var timestamp = text[i][3] !== "0" ? (text[i][3] + text[i][4]) : text[i][4];
				var timestamp = timestampRegex.exec(text[i]);
	      var timestampHour = timestamp[1];
	      var timestampMinute = timestamp[2];
	      var minute = parseInt(timestampHour) * 60 + parseInt(timestampMinute);
				if (minute !== 0) {
					$('#transcript-preview')[0].innerHTML += '<span class="preview-minute">[' + minute + ':00]&nbsp;</span>';
				}
				continue;
			}
			else if (first) {
				$('#transcript-preview')[0].innerHTML += text[i] + '<br />';
			}
		}

		$('#transcript-preview')[0].innerHTML += "</p>";

		addPreviewMinutes(playerControls);
	}
	else if (type.toLowerCase() == "index" && $('.indexAccordion')[0] != '') {
		// The current open work needs to be hidden to prevent editing while previewing
		$(".tag-add-segment").hide();
		$("#export").addClass('hidden');
		$(".preview-button").addClass('hidden');
		$("#preview-close").removeClass('hidden');

		$(".indexAccordion").clone().prop({ id: "previewAccordion", name: "indexClone"}).appendTo($('#input-index'));
		$(".indexAccordion").hide();
		$("#previewAccordion").show();

		// Initialize the new accordion
		$("#previewAccordion").accordion({
			header: "> div > h3",
			autoHeight: false,
			collapsible: true,
			clearStyle: true,
			active: false
		});

		$(".tag-edit").each(function() { if ($(this).parents('#previewAccordion').length) { $(this).remove(); } });
		$(".tag-delete").each(function() {
			if ($(this).parents('#previewAccordion').length) {
				$('<button class="btn btn-xs btn-primary preview-segment">Play Segment</button>').insertAfter($(this));
				$(this).remove();
			}
		});

		$("#previewAccordion").accordion("refresh");
		addPreviewSegments(playerControls);
	}
	else {
		errorHandler(new Error("The selected transcript or index document is empty."));
	}
}

// Here we return to editing work once we are finished with previewing the end result
const previewClose = function(playerControls) {
	// We'll stop the A/V media and return the playhead to the beginning
	playerControls.playerControls("beginning");
	playerControls.playerControls("stop");

	$("#transcript").show();
	$("#sync-controls").show();
	$("#transcript-preview").html('');
	$("#transcript-preview").hide();
	$(".tag-add-segment").show();
	$(".indexAccordion").show();
	$("div").remove("#previewAccordion");
	$("#export").removeClass('hidden');
	$(".preview-button").removeClass('hidden');
	$("#preview-close").addClass('hidden');
}

// Here we use prepared data for export to a downloadable file
const exportTranscript = function(sender, widget) {
	switch (sender) {
		case "vtt":
			var content = transcriptVTT();
			if (!content) break;

			// This will create a temporary link DOM element that we will click for the user to download the generated file
			var element = document.createElement('a');
		  element.setAttribute('href', 'data:text/vtt;charset=utf-8,' + encodeURIComponent(content));
		  element.setAttribute('download', 'transcript.vtt');
		  element.style.display = 'none';
		  document.body.appendChild(element);
		  element.click();
		  document.body.removeChild(element);

			break;

		default:
			errorHandler(new Error("This function is still under development."));
			break;
	}
}

const exportIndex = function(sender, widget) {
	switch (sender) {
		case "vtt":
			var content = indexVTT(widget);

			// This will create a temporary link DOM element that we will click for the user to download the generated file
			var element = document.createElement('a');
			element.setAttribute('href', 'data:text/vtt;charset=utf-8,' + encodeURIComponent(content));
			element.setAttribute('download', 'index.vtt');
			element.style.display = 'none';
			document.body.appendChild(element);
			element.click();
			document.body.removeChild(element);
			break;

		default:
			errorHandler(new Error("This function is still under development."));
			break;
	}
}
