// Modified by Mozzaz Inc.

var exec = cordova.require('cordova/exec');

var CallKit = function() {
	console.log('CallKit instanced');
};

CallKit.prototype.register = function(callChanged,audioSystem,callAccept,callDecline,callDismiss,callOpen) {
  var errorCallback = function() {};
  var successCallback = function(obj) {
    if (obj && obj.hasOwnProperty('callbackType')) {
      switch (obj.callbackType) {
        case "callChanged":
          /* this is a call changed callback! */
          callChanged(obj);
          break;
        case "audioSystem":
          /* this is an audio system callback! */
          audioSystem(obj.message);
          break;
        case "callAccept":
          //Call accepted
          callAccept(obj.uuid);
          break;
        case "callDecline":
          //Call declined
          callDecline(obj.uuid);
          break;
        case "callDismiss":
          //Call notification dismissed
          callDismiss(obj.uuid);
          break;
        case "callOpen":
          //Call notification default action
          callOpen(obj.uuid);
          break;
      }
    }
  };

  exec(successCallback, errorCallback, 'CallKit', 'register' );
};

CallKit.prototype.reportIncomingCall = function(name,params,onSuccess) {
	var supportsVideo = true;
	var supportsGroup = false;
	var supportsUngroup = false;
	var supportsDTMF = false;
	var supportsHold = false;

	if (typeof params === "boolean") {
		supportsVideo = params;
	} else if (typeof params === "object") {
		supportsVideo = (params.video === true);
		supportsGroup = (params.group === true);
		supportsUngroup = (params.ungroup === true);
		supportsDTMF = (params.dtmf === true);
		supportsHold = (params.hold === true);
	}

	var errorCallback = function() {};
	var successCallback = function(obj) {
		onSuccess(obj);
	};

	exec(successCallback, errorCallback, 'CallKit', 'reportIncomingCall', [name, supportsVideo, supportsGroup, supportsUngroup, supportsDTMF, supportsHold] );
};

CallKit.prototype.askNotificationPermission = function() {
	// TODO: allow user to pass a succes/error callback to know the user's answer
	var cb = function() {};
	exec(cb, cb, 'CallKit', 'askNotificationPermission', []);
};

CallKit.prototype.startCall = function(name,isVideo,onSuccess) {
	var errorCallback = function() {};
	var successCallback = function(obj) {
		onSuccess(obj);
	};

	exec(successCallback, errorCallback, 'CallKit', 'startCall', [name, isVideo] );
};

CallKit.prototype.callConnected = function(uuid) {
	var errorCallback = function() {};
	var successCallback = function() {};

	exec(successCallback, errorCallback, 'CallKit', 'callConnected', [uuid] );
};

CallKit.prototype.endCall = function(uuid,notify) {
	var errorCallback = function() {};
	var successCallback = function() {};

	exec(successCallback, errorCallback, 'CallKit', 'endCall', [uuid, notify] );
};

CallKit.prototype.finishRing = function(uuid) {
	var errorCallback = function() {};
	var successCallback = function() {};

	exec(successCallback, errorCallback, 'CallKit', 'finishRing', [uuid] );
};

if (typeof module != 'undefined' && module.exports) {
	module.exports = CallKit;
}
