package com.phonegap.videorecplugin;

import android.app.Activity;
import android.content.Intent;
import android.content.res.Configuration;
import android.media.MediaPlayer;
import android.os.*;
import android.view.MotionEvent;
import android.view.View;
import android.widget.*;
import android.util.DisplayMetrics;
import com.phonegap.video.R;

import java.io.File;

public class VideoPreview extends Activity {

    private LinearLayout m_statusView;
    private LinearLayout m_videoView;
    private LinearLayout m_controlView;

    private VideoView m_VideoView = null;

    private ImageView m_imgClose, m_imgDone;

    String videoPath = "";

    boolean bShowHideControlbar = true;

    Handler showhideHandler = new Handler();

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

        showhideHandler = new Handler()
        {
            @Override
            public void handleMessage(Message msg)
            {
                if (msg.what == 0)
                {
                    if (bShowHideControlbar)
                        showhideControlbar();
                }
            }
        };

        showhideHandler.sendEmptyMessageDelayed(0, 2000);
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

        //m_VideoView.setOnTouchListener(showhideControlbarTouchListener);
        m_VideoView.setOnTouchListener(new View.OnTouchListener() {
            @Override
            public boolean onTouch(View v, MotionEvent event) {
                // do nothing here......

                if (event.getAction() != MotionEvent.ACTION_UP)
                    return true;

                showhideControlbar();

                return true;
            }
        });

        m_imgDone.setImageResource(R.drawable.video_sprites_next);

        setVideoViewSize();
    }

    private void setVideoViewSize()
    {
        DisplayMetrics metrics = new DisplayMetrics(); getWindowManager().getDefaultDisplay().getMetrics(metrics);

        android.widget.LinearLayout.LayoutParams params = (android.widget.LinearLayout.LayoutParams) m_VideoView.getLayoutParams();

        params.width = metrics.widthPixels;
        params.height = metrics.heightPixels;
        //params.height = (int)(metrics.heightPixels * 2 / 3);
        params.leftMargin = 0;
        m_VideoView.setLayoutParams(params);
    }

    private View.OnClickListener closeClickListener = new View.OnClickListener() {
        @Override
        public void onClick(View v) {
            m_VideoView.stopPlayback();

            Intent intent = new Intent(VideoPreview.this, VideoRecord.class);

            if (intent != null)
            {
                startActivity(intent);
            }
            
            finish();
        }
    };

    private View.OnClickListener doneClickListener = new View.OnClickListener() {
        @Override
        public void onClick(View v) {

            finish();
        }
    };

    public void showhideControlbar() {

        android.widget.LinearLayout.LayoutParams statusParams = (android.widget.LinearLayout.LayoutParams) m_statusView.getLayoutParams();
        android.widget.LinearLayout.LayoutParams controlParams = (android.widget.LinearLayout.LayoutParams) m_controlView.getLayoutParams();

        if (bShowHideControlbar)
        {
            statusParams.weight = 0;
            m_statusView.setLayoutParams(statusParams);

            controlParams.weight = 0;
            m_controlView.setLayoutParams(controlParams);
        }
        else
        {
            statusParams.weight = 0.7f;
            m_statusView.setLayoutParams(statusParams);

            controlParams.weight = 1;
            m_controlView.setLayoutParams(controlParams);

            showhideHandler.sendEmptyMessageDelayed(0, 2000);
        }

        bShowHideControlbar = !bShowHideControlbar;
    }

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

        setVideoViewSize();
    }
}
