(function () {
	"use strict";

	function SendOriginResponse(request, position) {
		var response = {
			request_id: Number(request.request_id) || 0,
			origin_token: Number(request.origin_token) || 0,
		};

		if (position && position.length >= 3) {
			var x = Number(position[0]);
			var y = Number(position[1]);
			var z = Number(position[2]);
			if (isFinite(x) && isFinite(y) && isFinite(z)) {
				response.x = x;
				response.y = y;
				response.z = z;
			}
		}

		GameEvents.SendCustomGameEventToServer(
			"camera_motion_origin_response",
			response
		);
	}

	function OnOriginRequest(request) {
		request = request || {};
		var position = null;
		if (typeof GameUI.GetCameraLookAtPosition === "function") {
			position = GameUI.GetCameraLookAtPosition();
		}
		SendOriginResponse(request, position);
	}

	GameEvents.Subscribe("camera_motion_origin_request", OnOriginRequest);
})();
