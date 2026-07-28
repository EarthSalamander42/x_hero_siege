(function() {
	"use strict";

	var windowStartedAt = Date.now();
	var frameStartedAt = windowStartedAt;
	var frameDurations = [];
	var frameCount = 0;
	var REPORT_INTERVAL_MS = 5000;
	var MAX_FRAME_SAMPLES = 1000;

	function percentile(sorted, ratio) {
		if (sorted.length === 0) return 0;
		var index = Math.max(0, Math.min(sorted.length - 1, Math.ceil(sorted.length * ratio) - 1));
		return sorted[index];
	}

	function report(now) {
		var elapsed = Math.max(1, now - windowStartedAt);
		var sorted = frameDurations.slice(0).sort(function(a, b) { return a - b; });
		var frameP95 = percentile(sorted, 0.95);
		var fpsAverage = frameCount * 1000 / elapsed;
		var fpsP5 = frameP95 > 0 ? 1000 / frameP95 : fpsAverage;

		GameEvents.SendCustomGameEventToServer("xhs_performance_client_sample", {
			fps_average: Math.max(0, Math.min(500, Math.round(fpsAverage * 10) / 10)),
			fps_p5: Math.max(0, Math.min(500, Math.round(fpsP5 * 10) / 10)),
			frame_ms_p95: Math.max(0, Math.min(1000, Math.round(frameP95 * 10) / 10))
		});

		windowStartedAt = now;
		frameDurations = [];
		frameCount = 0;
	}

	function tick() {
		var now = Date.now();
		var duration = now - frameStartedAt;
		frameStartedAt = now;
		frameCount += 1;
		if (duration >= 0 && duration <= 1000 && frameDurations.length < MAX_FRAME_SAMPLES) {
			frameDurations.push(duration);
		}
		if (now - windowStartedAt >= REPORT_INTERVAL_MS) report(now);
		$.Schedule(0.0, tick);
	}

	tick();
})();
