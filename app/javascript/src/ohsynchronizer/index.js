require("jquery-ui/ui/widgets/accordion");
require('bootstrap/js/dist/modal.js');
import { closeButtons, errorHandler, timecodeRegEx } from './functions';
import { uploadsuccess } from './events';
import { exportIndex, indexVTT } from './export';
import { timestampAsSeconds } from './timeStamps';

const segmentHtml = function(segment) {
	var panel = '<div id="' + segment.startTime + '" class="segment-panel">';
	panel += '<h3>' + segment.startTime + '-<span class="tag-title">' + segment.title + '</span></h3>';
	panel += '<div>';
	panel += '<div class="pull-right"><button class="btn btn-xs btn-secondary tag-edit">Edit</button> ';
	panel += '<button class="btn btn-xs btn-primary tag-delete">Delete</button></div>';
	panel += '<p>Synopsis: <span class="tag-segment-synopsis">' + segment.description + "</span></p>";
	panel += '<p>Keywords: <span class="tag-keywords">' + segment.keywords + "</span></p>";
	panel += '<p>Subjects: <span class="tag-subjects">' + segment.subjects + "</span></p>";
	panel += '<p>Partial Transcript: <span class="tag-partial-transcript">' + segment.partialTranscript + "</span></p>";
	panel += '</div></div>';
	return panel;
}

export default class Index {
	constructor(id, options = {}) {
		this.type = 'index';
		this.previewOnly = options.previewOnly;
		this.indexDiv = $('#' + id);
		this.indexDiv.attr('data-editVar','-1');
		this.indexDiv.attr('data-endTime','0');
		this.duration = -1;
	}

	setUpControls(playerControls) {
		this.duration = playerControls.duration();
		if (this.previewOnly) {
			$(".tag-add-segment").hide();
		} else {
			$('.tag-add-segment').on("click", function () {
					$(".tag-controls").show();
					playerControls.updateTimestamp();
			});
			var index = this;
			$('.index-tag-save').on('click', function(){
				index.tagSave();
			});
			$('.index-tag-cancel').on('click', function(){
				index.tagCancel();
			});
			$('.synch-download-button').on('click', function() { exportIndex('vtt', index); });
		}
	}

	dispose() {
		$('.index-tag-save').off('click');
		$('.index-tag-cancel').off('click');
		$('.synch-download-button').off('click');
		$('.tag-edit').off('click');
		$('.preview-segment').off('click');
		$('.close').off('click');
		$('.tag-delete').off('click');
		$('.tag-add-segment').off('click');
	}

	initializeAccordion() {
		this.accordion().accordion({
			header: "> div > h3",
			autoHeight: false,
			collapsible: true,
			clearStyle: true,
			active: false
		});
	}

	accordion() {
		return this.indexDiv.find(".indexAccordion") || this.indexDiv.append('<div class="indexAccordion"></div>');
	}

	addSegment(segment) {
		var newPanel = this.accordion().append(segmentHtml(segment));
		return newPanel;
	}

	renderText(file, ext, playerControls) {
		var reader = this.fileReader(file, ext, playerControls);
		if (reader) reader.readAsText(file);
	}

	// Here we display index or transcript file data
	fileReader(file, ext, playerControls) {
		var reader = new FileReader();
		var index = this;
		if (ext != 'vtt') {
			errorHandler(new Error("Not a valid file extension."));
			return;
		}
		try {
			// VTT Parsing
			reader.onload = function(event) {
				var target = event.target.result;

				index.initializeAccordion();
				$("#finish-area").show();

				if (target.indexOf("WEBVTT") !== 0) {
					errorHandler(new Error("Not a valid VTT index file."));
					return;
				}
				// Having interview-level metadata is required
				if (!/(Title:)+/.test(target) || !/(Date:)+/.test(target) || !/(Identifier:)+/.test(target)) {
					errorHandler(new Error("Not a valid index file - missing interview-level metadata."));
					return;
				}
				uploadsuccess(new CustomEvent("uploadsuccess", {detail: file}));
				closeButtons();
				// We'll break up the file line by line
				var text = target.split(/\r?\n|\r/);

				var k = 0;
				for (k; k < text.length; k++) {
					if (timecodeRegEx.test(text[k])) { break; }
					if ($('#interview-metadata').attr('data-assigned') == 'true') { continue; }
					// First we pull out the interview-level metadata
					if (/(Title:)+/.test(text[k])) {
						// Save the interview title
						$('#tag-interview-title').val(text[k].slice(7));

						// Then add the rest of the information to the metadata section
						while (text[k] !== '' && k < text.length) {
							$('#interview-metadata')[0].innerHTML += text[k] + '<br />';
							k++;
						}
					}
				}

				// And we can remove the lines we've already seen to make segment parsing easier
				for (var j = k - 1; j >= 0; j--) {
					text.shift();
				}

				// Now we build segment panels
				var accordion = index.accordion();
				var timestamp = '';
				var title = '';
				var transcript = '';
				var synopsis = '';
				var keywords = '';
				var subjects = '';

				for (var i = 0; i < text.length; i++) {
					// We are only concerned with timestamped segments at this point of the parsing
					if (timecodeRegEx.test(text[i])) {
						timestamp = text[i].substring(0, 12);
						// read json data from subsequent lines, line by line, until an indented end brace is encountered
						let indexJson = '';
						i++;
						while (text[i] !== "}" && i < text.length) {
							indexJson += text[i];
							if (text[i] === '}') break;
							i++;

						}
						indexJson += '}';
						const indexObj = JSON.parse(indexJson);

						// Now that we've gathered all the data for the variables, we build a panel
						index.addSegment({
							startTime: timestamp,
							title: indexObj.title,
							description: indexObj.description,
							keywords: indexObj.keywords,
							subjects: indexObj.subjects,
							partialTranscript: indexObj.partial_transcript
						});
					}
				}

				index.sortAccordion();
				index.tagEdit(playerControls);
				index.tagCancel();
				closeButtons();
				if (index.previewOnly) index.initPreviewControls(index.accordion(), playerControls);
			}
			return reader;
		} catch (e) { errorHandler(e); }
	}

	// Here we save the contents of the Tag Segment modal
	tagSave() {
		var edit = this.indexDiv.attr('data-editVar');
		var segment = {};
		segment.startTime = $("#tag-timestamp").val();
		segment.title = $("#tag-segment-title").val();
		segment.partialTranscript = $("#tag-partial-transcript").val();
		segment.keywords = $("#tag-keywords").val();
		segment.subjects = $("#tag-subjects").val();
		segment.description = $("#tag-segment-synopsis").val();

		// Get an array of jQuery objects for each accordion panel
		var panelIDs = $(".indexAccordion > div").map(function(panel) {
			var id = $(panel).attr('id');
			if (id !== edit) return id;
		});

		if (segment.title === "" || segment.title === null) alert("You must enter a title.");
		else if ($.inArray(segment.startTime, panelIDs) > -1) alert("A segment for this timestamp already exists.");
		else {
			// If we're editing a panel, we need to remove the existing panel from the accordion
			if (edit !== "-1") {
				var editPanel = document.getElementById(edit);
				editPanel.remove();
			}

			this.addSegment(segment);
			this.sortAccordion(edit);

			this.tagEdit();
			this.tagCancel();
			closeButtons();
		}
	}

	// Here we enable the edit buttons for segments
	tagEdit(playerControls) {
		var widget = this;
		$('.tag-edit').on('click', function(){
			// Pop up the modal
			$('#index-tag').modal('show');

			// Get our data for editing
			var id = $(this).closest('.segment-panel');
			var timestamp = id.attr('id');
			var title = id.find(".tag-title").text();
			var synopsis = id.find(".tag-segment-synopsis").text();
			var keywords = id.find(".tag-keywords").text();
			var subjects = id.find(".tag-subjects").text();
			var transcript = id.find(".tag-partial-transcript").text();

			// Tell the global variable we're editing
			widget.indexDiv.attr('data-editVar',timestamp);

			// Set the fields to the appropriate values
			$("#tag-timestamp").val(timestamp);
			$("#tag-segment-title").val(title);
			$("#tag-segment-synopsis").val(synopsis);
			$("#tag-keywords").val(keywords);
			$("#tag-subjects").val(subjects);
			$("#tag-partial-transcript").val(transcript);

			playerControls.seekTo(timestampAsSeconds(timestamp));
			playerControls.playerControls("play");
		});
	}

	// Here we clear and back out of the Tag Segment modal
	tagCancel() {
		$("#tag-segment-title").val("");
		$("#tag-partial-transcript").val("");
		$("#tag-keywords").val("");
		$("#tag-subjects").val("");
		$("#tag-segment-synopsis").val("");
		$("#index-tag").modal('hide');
		this.indexDiv.attr('data-editVar',"-1");
	}

	// Here we sort the accordion according to the timestamp to keep the parts in proper time order
	sortAccordion(activateId = null) {
		var accordion = this.accordion();
		// Get an array of jQuery objects for each accordion panel
		var entries = $.map(accordion.children("div").get(), function(entry) {
			var $entry = $(entry);
			return $entry;
		});

	  // Sort the array by the div's id
		entries.sort(function(a, b) {
			var timeA = new Date('1970-01-01T' + a.attr('id') + 'Z');
			var timeB = new Date('1970-01-01T' + b.attr('id') + 'Z');
			return timeA - timeB;
		});

		// Put them in the right order in the accordion
		var activateIndex = -1;
		$.each(entries, function(index) {
			this.detach().appendTo(accordion);
			if (this.attr('id') == activateId) {
				activateIndex = index;
			}
		});
		accordion.accordion( "option", "active", false);
		accordion.accordion("refresh");
		// if a panel was edited, activate it
		if (activateIndex !== -1) accordion.accordion( "option", "active", activateIndex);
	}

	preview(playerControls) {
		var accordion = this.accordion();
		if (accordion[0] != '') {
			// The current open work needs to be hidden to prevent editing while previewing
			$(".tag-add-segment").hide();
			$("#export").addClass('hidden');
			$(".preview-button").addClass('hidden');
			$("#preview-close").removeClass('hidden');

			accordion.clone().prop({ id: "previewAccordion", name: "indexClone"}).appendTo($('#input-index'));
			accordion.hide();
			$("#previewAccordion").show();

			// Initialize the new accordion
			$("#previewAccordion").accordion({
				header: "> div > h3",
				autoHeight: false,
				collapsible: true,
				clearStyle: true,
				active: false
			});
			this.initPreviewControls($("#previewAccordion"), playerControls);
		} else {
			errorHandler(new Error("The selected index document is empty."));
		}
	}

	initPreviewControls(accordion, playerControls) {
		accordion.find(".tag-edit").each(function() { $(this).remove(); });
		accordion.find(".tag-delete").each(function() {
			$('<button class="btn btn-xs btn-primary preview-segment">Play Segment</button>').insertAfter($(this));
			$(this).remove();
		});

		accordion.accordion("refresh");
		$('.preview-segment').on('click', function(){
			var timestamp = $(this).closest(".segment-panel").attr("id");
			playerControls.seekTo(timestampAsSeconds(timestamp));
			playerControls.playerControls("play");
		});
	}

	exportVTT() {
		return indexVTT(this, this.duration);
	}
}