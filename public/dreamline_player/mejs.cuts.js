// convert 4:30 to 4.5
function convertTime(str) {
	var a = str.split(":"),
		time = (parseInt(a[0]) * 60 + parseInt(a[1])) / 60;

	return time.toFixed(2);
}

/*
 MediaElement Cuts Plugin
 Only play parts of a video, according to data specified in an external json.
 Three ways to activate:
 1. <video ... data-cuts="data.json"></video>
 2. $('video').mediaelementplayer({ ... features: [...,'cuts'], cutsJSON: "data.json" });
 3. $('video').cutsInit('data.json');
 */

// define text stings
$.extend(mejs.MepDefaults, {
	cutsTexts: {
		select: 'Select Cut',
		all: 'All Video'
	},
	cutsJSON: false,
	cutsFade: true
});

$.extend(MediaElementPlayer.prototype, {
	buildcuts: function (player, controls, layers, media) {
		var url = this.$node.data('cuts') || this.options.cutsJSON;

		if (url)
			this.cutsInit(url);
		else
			console.error('MediaElement Cuts Plugin -- no cut JSON file was found');
	},

	// initiate plugin
	cutsInit: function(url) {
		var t = this,
			texts = t.options.cutsTexts;

		t.cuts = {
			all: { name: t.options.cutsTexts.all, isAll: true, segments: [[0]] }
		};

		// load data from server
		$.getJSON(url, function(data) {
			t.cuts.data = data;
			t.populateCuts(data);
		});

		// wait till timeline loads to create the segments
		t.container.on('controlsready', function() {
			t.cuts.segments = $('<ul class="mejs-time-segments"></ul>')
				.appendTo(t.controls.find('.mejs-time-total'));
			t.container.trigger('segmentsready');
		});

		// create button
		t.cuts.button =
			$('<div class="mejs-cuts-button">'+
				'<button aria-controls="' + t.id + '" title="' + texts.select + '">' + texts.select + '</button>'+
				'<div class="mejs-cuts-selector">'+
					'<ul>'+
						'<li><label>'+
							'<input type="radio" name="'+ t.id +'_cuts" value="all" checked="checked" />' +
							texts.all+
						'</label></li>'	+
					'</ul>'+
				'</div>'+
			'</div>')
				.appendTo(t.controls)

				// on hover open cut selector
				.hover(function() {
					t.cuts.button.find('.mejs-cuts-selector').toggle();
				})

				// handle clicks radio buttons
				.on('click', 'input[type=radio]', function() {
					t.loadCut(this.value);
				});

		// create fadescreen
		t.cuts.fadescreen =
			$('<div class="mejs-overlay mejs-layer mejs-cuts-fade"></div>')
				.appendTo(t.container.find('.mejs-layers'));

		// find play overlay
		t.cuts.playOverlay = t.container.find('.mejs-overlay-play div');

		// resize segments on fullscreen
		t.controls.on('click', '.mejs-fullscreen-button button', function() {
			t.resizeSegments();
		});

		var last = 0;
		t.media.addEventListener('timeupdate', function() {
			if (t.media.currentTime == last)
				return;

			last = t.media.currentTime;
			t.playCurrentCut();
		}, false);
	},

	// play only the current cut's segments
	playCurrentCut: function() {
		if (this.cuts.current.isAll)
			return;

		var t = this,
			segments = t.cuts.current.segments,
			curr = t.media.currentTime;

		for (var i in segments) {
			// in segment
			if (segments[i][0] <= curr && curr <= segments[i][1]) {
				console.log(curr+' in segment '+i+' ['+segments[i][0]+','+segments[i][1]+']');
				return;
			}
			// not in segment, jump to next
			if (curr < segments[i][0]) {
				console.log(curr+' jumping to '+segments[i][0]+' in segment '+i);

				// still the first segment
				if (i == 0 || !this.options.cutsFade) {
					t.media.setCurrentTime(segments[i][0]);
					//t.media.play();
					return;
				}

				// fadein and out
				t.cuts.playOverlay.hide();
				t.media.pause();
				t.cuts.fadescreen.fadeIn(400, function() {
					t.media.setCurrentTime(segments[i][0]);
					t.cuts.fadescreen.fadeOut(400, function() {
						t.media.play();
						t.cuts.playOverlay.show();
					});
				});
				return;
			}
		}
		// end of cut
		t.media.pause();

		if (curr > segments[i][1]+0.2) {
			console.log('end. '+curr+' > '+(segments[i][1]+0.2), 'jumping to '+segments[0][0]);
			t.media.setCurrentTime(segments[0][0]);
			t.media.pause();
		}

	},

	// populate cuts data
	populateCuts: function(data) {
		var t = this,
			ul = t.cuts.button.find('ul');

		for (var i in data.cuts) {
			// fill cut selector
			var cut =
				$('<li>' +
					'<label title="'+data.cuts[i].name+'">'+
						'<input type="radio" name="'+ t.id +'_cuts" value="'+ i +'" />' +
						data.cuts[i].name +
					'</label>' +
				'</li>')
					.appendTo(ul);

			// if default, load it
			if (data.defaultCut == data.cuts[i].name) {
				//console.log(data.cuts[i].segments[0][0]);

				if (t.cuts.segments)
					cut.find('input').click()
				else // the timeline, and therefore the segments element, is not ready
					t.container.on('segmentsready', function() {
						cut.find('input').click();
					});
			}
		}
	},

	// load selected cut
	loadCut: function(cutIndex) {
		var t = this,
			cut = t.cuts.current = t.cuts.data.cuts[cutIndex] || t.cuts.all;

		// update button text
		t.cuts.button.find('button').text(cut.name);

		// update timeline
		t.cuts.segments.empty();
		t.drawSegments(cut.segments);
	},

	drawSegments: function(segments) {
		var t = this;
		for (var i in segments)
			$('<li class="mejs-segment" data-start="'+segments[i][0]+'" data-end="'+segments[i][1]+'"></li>')
				.appendTo(t.cuts.segments);

		if (t.media.duration) {
			t.resizeSegments();
			t.media.setCurrentTime(segments[0][0]);
		}
		else // wait till we have duration to resize
			t.media.addEventListener('loadedmetadata', function(e) {
				t.resizeSegments();
				t.media.setCurrentTime(segments[0][0]);
			}, false);
	},

	resizeSegments: function() {
		var w = this.total.width(),
			d = this.media.duration;
		this.cuts.segments.find('li').each(function() {
			var s = $(this);
			s.css({
				width:	w * ( s.data('end') - s.data('start') ) / d,
				left:	w * s.data('start') / d
			});
		});

	}
});