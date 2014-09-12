package com.phonegap.videorecplugin;

import java.io.File;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;


public class VideoRecPreview extends CordovaPlugin {
	
	private static final int VIDEO_RECORDE = 2;     // Constant for video recording
	
	private CallbackContext callback;
		
	public static final String PREF_NAME = "VideoRecPreview";
	
	@Override
	public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
				
		this.callback = callbackContext;
		
		if (action.equals("startVideoRecordPreview")) {
			
			Intent intent = new Intent(this.cordova.getActivity(), VideoRecord.class);
			
			this.cordova.startActivityForResult(this, intent, VIDEO_RECORDE);
			
            return true;
		}
		
        return false;
	}
	
	public void onActivityResult(int requestCode, int resultCode, Intent intent) {
		if (resultCode == Activity.RESULT_OK) {
			if (requestCode == VIDEO_RECORDE) {
		        if (intent == null)
		        {
		          this.callback.sendPluginResult(new PluginResult(PluginResult.Status.ERROR, "Error: data is null"));
		        }
		        else
		        {
		        	final String videopath = intent.getStringExtra("VideoPath");
	        		// Send Path back to JavaScript for viewing video
	        		this.callback.sendPluginResult(new PluginResult(PluginResult.Status.OK, videopath));
	        		
	                /*cordova.getActivity().runOnUiThread(new Runnable() {
	                    public void run() {
	                    	
	    	    			Intent videopreviewIntent = new Intent(cordova.getActivity(), VideoPreview.class);
	    	    			videopreviewIntent.putExtra("videoPath", videopath);
	    	    			
	    	        		cordova.getActivity().startActivity(videopreviewIntent);
		                    //callback.success();
	                    }
	                });*/
	        		
		        }
			}
		}
	}
}