package com.phonegap.videorecplugin;

import android.app.Activity;
import android.content.Intent;
import android.content.res.Configuration;
import android.media.MediaPlayer;
import android.os.*;
import android.view.View;
import android.widget.*;

import java.io.File;

public class VideoPreview extends Activity {

    private LinearLayout m_statusView;
    private LinearLayout m_videoView;
    private LinearLayout m_controlView;

    private VideoView m_VideoView = null;

    private ImageView m_imgClose, m_imgDone;

    String videoPath = "";

    /**
     * Called when the activity is first created.
     */
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.videopreview);

        Intent intent = getIntent();
        videoPath = intent.getStringExtra("videoPath");

        getControlVariables();
        initializeUI();

        File file = new File(videoPath);
        if (file.exists())
        {
            try {
                MediaController mediaController = new MediaController(this);
                mediaController.setAnchorView(m_videoView);
                m_VideoView.setMediaController(null);
                m_VideoView.setKeepScreenOn(true);
                m_VideoView.setVideoPath(videoPath);
                m_VideoView.setOnPreparedListener(new MediaPlayer.OnPreparedListener() {

                    @Override
                    public void onPrepared(MediaPlayer mp) {
                        // TODO Auto-generated method stub
                        mp.setLooping(true);
                        m_VideoView.start();
                    }
                });

            } catch (Exception e) {
                // TODO: handle exception
                //Toast.makeText(this, "Error connecting", Toast.LENGTH_SHORT).show();
            }
        }
    }

    private void getControlVariables()
    {
        m_statusView = (LinearLayout) findViewById(R.id.statusView);
        m_videoView = (LinearLayout) findViewById(R.id.videoView);
        m_controlView = (LinearLayout) findViewById(R.id.controlView);

        m_imgClose = (ImageView) findViewById(R.id.imgClose);
        m_imgDone = (ImageView) findViewById(R.id.imgDone);

        m_VideoView = (VideoView) findViewById(R.id.VideoView);
    }

    private void initializeUI()
    {
        m_imgClose.setOnClickListener(closeClickListener);
        m_imgDone.setOnClickListener(doneClickListener);

        m_imgDone.setImageResource(R.drawable.video_sprites_next);
    }

    private View.OnClickListener closeClickListener = new View.OnClickListener() {
        @Override
        public void onClick(View v) {
            m_VideoView.stopPlayback();

            finish();
        }
    };

    private View.OnClickListener doneClickListener = new View.OnClickListener() {
        @Override
        public void onClick(View v) {
        }
    };

    @Override
    public void onConfigurationChanged(Configuration newConfig) {
        super.onConfigurationChanged(newConfig);

        float scale = getResources().getDisplayMetrics().density;

        if (newConfig.orientation == Configuration.ORIENTATION_PORTRAIT)
        {
            m_statusView.setPadding(0, (int)(20 * scale + 0.5f), 0, (int)(20 * scale + 0.5f));
            m_controlView.setPadding(0, (int)(30 * scale + 0.5f), 0, (int)(30 * scale + 0.5f));
        }
        else if (newConfig.orientation == Configuration.ORIENTATION_LANDSCAPE)
        {
            m_statusView.setPadding(0, (int)(5 * scale + 0.5f), 0, (int)(5 * scale + 0.5f));
            m_controlView.setPadding(0, (int)(10 * scale + 0.5f), 0, (int)(10 * scale + 0.5f));
        }
    }
}
