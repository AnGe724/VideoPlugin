cordova.define("cordova/plugin/VideoRecordPreviewPlugin", function(require, exports, module) {
               
               var exec = require('cordova/exec');
               var VideoRecordPreviewPlugin = function(){};
               
               VideoRecordPreviewPlugin.prototype.startVideoRecordPreview = function(success, failure, options) {
                  exec(success, failure, "VideoRecPreview", "startVideoRecordPreview", [options]);
               };

               var myplugin = new VideoRecordPreviewPlugin();
               
               module.exports = myplugin;
               
               });

var VideoRecordPreviewPlugin = cordova.require("cordova/plugin/VideoRecordPreviewPlugin");

module.exports = VideoRecordPreviewPlugin;
