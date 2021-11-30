/** Transcript Sync Functions **/
OHSynchronizer.Transcript = function(id, options = {}){
	Object.call(this);
	this.contentDiv = $('#' + id);
	this.type = 'transcript';
	this.previewOnly = options.previewOnly;
}

OHSynchronizer.Transcript.prototype.constructor = OHSynchronizer.Transcript;

OHSynchronizer.Transcript.prototype.dispose = function() {
	$('.transcript-word').off('click');
	$('.transcript-timestamp').off('click');
	$('.transcript-timestamp').off('dblclick');
}

OHSynchronizer.Transcript.prototype.fileReader = function(file, ext) {
	var reader = new FileReader();
	var transcript = this;
	try {
		reader.onload = function(event) {
			var target = event.target.result;

			// If there's no A/V present, there is no transcript Syncing
			if (!($("#audio").is(':visible')) && !($("#video").is(':visible')) && $("#ytplayer")[0].innerHTML === '') {
				OHSynchronizer.errorHandler(new Error("You must first upload an A/V file in order to sync a transcript."));
			} else {
			// VTT Parsing

				if (ext === 'vtt') {
					$("#finish-area").show();

					if (!(OHSynchronizer.Import.timecodeRegEx.test(target)) || target.indexOf("WEBVTT") !== 0){
						OHSynchronizer.errorHandler(new Error("Not a valid VTT transcript file."));
					} else {
						if ($("#audio").is(':visible') || $("#video").is(':visible') || $("#ytplayer")[0].innerHTML != '') {
							if (!transcript.previewOnly) $("#sync-controls").show();
						}
						OHSynchronizer.Events.uploadsuccess(new CustomEvent("uploadsuccess", {detail: file}));
						OHSynchronizer.Index.closeButtons();
						// We'll break up the file line by line
						var text = target.split(/\r?\n|\r/);

						// We implement a Web Worker because larger transcript files will freeze the browser
						if (window.Worker) {
							var workerSrc = (transcript.previewOnly) ? (OHSynchronizer.webWorkers + "/transcript-preview.js") : (OHSynchronizer.webWorkers + "/transcript.js");
							var textWorker = new Worker(workerSrc);
							textWorker.postMessage(text);
							textWorker.onmessage = function(e) {
								$('#transcript')[0].innerHTML += e.data;

								// Enable click functions, addSyncMarker calls all three functions
								if (transcript.previewOnly) {
									transcript.initPreviewControls();
								} else {
									transcript.addSyncMarker();
								}
							}
						}
					}
				}
				else OHSynchronizer.errorHandler(new Error("Not a valid file extension."));
			}
		}
		return reader;
	} catch (e) { OHSynchronizer.errorHandler(e); }
}

OHSynchronizer.Transcript.prototype.renderText = function(file, ext) {
	var reader = this.fileReader(file, ext);
	if (reader) reader.readAsText(file);
}

// Here we add a Sync Marker
OHSynchronizer.Transcript.prototype.addSyncMarker = function() {
	$('.transcript-word').on('click', function(){
		var minute = parseInt($("#sync-minute").html());
		if (minute == 0) minute++;
		var marker = "{" + minute + ":00}";
		var regEx = new RegExp(marker);

		// If this word is already a sync marker, we don't make it another one
		if ($(this).hasClass('transcript-clicked')) {
			OHSynchronizer.errorHandler(new Error("Word already associated with a transcript sync marker."));
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
			$('<span class="transcript-timestamp">{' + minute + ':00}&nbsp;</span>').insertBefore($(this));

			// Increase the Sync Current Mark
			$("#sync-minute")[0].innerHTML = minute + 1;

			OHSynchronizer.Transcript.updateCurrentMark();
			OHSynchronizer.Transcript.removeSyncMarker();

			// If we are looping, we automatically jump forward
			if (OHSynchronizer.looping !== -1) {
				$("#sync-minute").html(minute);
				OHSynchronizer.Transcript.syncControl("forward", OHSynchronizer.playerControls);
			}
		}
	});
}

OHSynchronizer.Transcript.prototype.preview = function() {
	OHSynchronizer.looping = -1;
	$("#transcript").hide();
	$("#sync-controls").hide();
	$("#transcript-preview").show();
	$("#export").addClass('hidden');
	$(".preview-button").addClass('hidden');
	$("#preview-close").removeClass('hidden');

	var content = OHSynchronizer.Export.transcriptVTT().split(/\r?\n|\r/);
	var transcript = this;
	if (window.Worker) {
		var textWorker = new Worker(OHSynchronizer.webWorkers + "/transcript-preview.js");
		textWorker.onmessage = function(e) {
			$("#transcript-preview").html(e.data);
			transcript.initPreviewControls();
		}
		textWorker.postMessage(content);
	}
}

OHSynchronizer.Transcript.prototype.initPreviewControls = function() {
	$('.preview-minute').on('click', function(){
		var timestamp = $(this)[0].innerText.split('[');
		var minute = timestamp[1].split(':');
		OHSynchronizer.playerControls.seekMinute(parseInt(minute[0]));
	});
}

OHSynchronizer.Transcript.prototype.exportVTT = function() {
	return OHSynchronizer.Export.transcriptVTT();
}

// Here we update Transcript Sync Current Mark
OHSynchronizer.Transcript.updateCurrentMark = function() {
	$('.transcript-timestamp').on('click', function(){
		var mark = $(this).html();
		mark = mark.replace("{", '');
		var num = mark.split(":");
		$("#sync-minute").html(num[0]);
	})
}

// Here we remove a Transcript Sync Marker
OHSynchronizer.Transcript.removeSyncMarker = function() {
	$('.transcript-timestamp').on('dblclick', function(){
		$(this).next(".transcript-clicked").removeClass('transcript-clicked');
		$(this).remove();
	});
}

// Here we capture Transcript sync control clicks
OHSynchronizer.Transcript.syncControl = function(type, playerControls) {
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
