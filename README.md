VideoPlugin
===========

Record &amp; Preview Video Phonegap Plugin for iOS &amp; Android.

### Plugin's Purpose
This plugin records video with camera of the phone and previews recorded video.

## Supported Platforms
- **iOS**<br>

## Dependencies
[Cordova][cordova] will check all dependencies and install them if they are missing.


## Installation
The plugin can either be installed into the local development environment or cloud based through [PhoneGap Build][PGB].

### Adding the Plugin to your project
Through the [Command-line Interface][CLI]:
```bash
# ~~ from master ~~
cordova plugin add https://github.com/dantesanh724/VideoPlugin.git && cordova prepare
```

### Removing the Plugin from your project
Through the [Command-line Interface][CLI]:
```bash
cordova plugin rm com.anh724.cordova.plugin.videorecordpreview
```

### PhoneGap Build
Add the following xml to your config.xml to always use the latest version of this plugin:
```xml
<gap:plugin name="com.anh724.cordova.plugin.videorecordpreview" />
```
or to use an specific version:
```xml
<gap:plugin name="com.anh724.cordova.plugin.videorecordpreview" version="1.0.0" />
```
More informations can be found [here][PGB_plugin].


## Using the plugin
The plugin creates the object ```window.plugin.videorecordpreview``` with the following methods:

### Plugin initialization
The plugin and its methods are not available before the *deviceready* event has been fired.

```javascript
document.addEventListener('deviceready', function () {
    // window.plugin.videorecordpreview is now available
}, false);
```

### startVideoRecordPreview
Retrieves recorded path from the device.<br>

```javascript
window.plugin.videorecordpreview.startVideoRecordPreview(onSuccess, onCancel);
```

This function record the video with camera of the phone and preview recorded video.
The return value will be sent to the [onsuccess] function, it has string value as following formats;
```javascript
{
  '/private/var/mobile/Applications/6A.../video_....m4v'
};
```

## Full Example
```html
<!DOCTYPE html>
<html>
    <head>
        <meta charset="utf-8" />
        <meta name="format-detection" content="telephone=no" />
        <!-- WARNING: for iOS 7, remove the width=device-width and height=device-height attributes. See https://issues.apache.org/jira/browse/CB-4323 -->
        <meta name="viewport" content="user-scalable=no, initial-scale=1, maximum-scale=1, minimum-scale=1, width=device-width, height=device-height, target-densitydpi=device-dpi" />
        <link rel="stylesheet" type="text/css" href="css/index.css" />
        <meta name="msapplication-tap-highlight" content="no" />
        <title>Hello World</title>
    </head>
    <body>
        <div class="app">
            <h1>Apache Cordova</h1>
            <div id="deviceready" class="blink">
                <p class="event listening">Connecting to Device</p>
                <p class="event received">Device is Ready</p>
            </div>
        </div>
        <script type="text/javascript" src="cordova.js"></script>
        <script type="text/javascript" src="js/index.js"></script>
        <script type="text/javascript">
            
	    app.initialize();

	    window.plugin.videorecordpreview.startVideoRecordPreview(function(url){alert(url);}, function(error){alert(error);});

        </script>
    </body>
</html>
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

This software is released under the [Apache 2.0 License][apache2_license].

© 2013-2014 Snaphappi, Inc. All rights reserved

[cordova]: https://cordova.apache.org
[PGB_plugin]: https://build.phonegap.com/plugins/413
[CLI]: http://cordova.apache.org/docs/en/3.0.0/guide_cli_index.md.html#The%20Command-line%20Interface
[PGB]: http://docs.build.phonegap.com/en_US/3.3.0/index.html
[apache2_license]: http://opensource.org/licenses/Apache-2.0
