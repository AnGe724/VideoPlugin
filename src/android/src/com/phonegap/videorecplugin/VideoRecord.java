package com.phonegap.videorecplugin;

import android.app.Activity;
import android.app.ProgressDialog;
import android.content.Intent;
import android.content.res.Configuration;
import android.graphics.Point;
import android.graphics.Rect;
import android.hardware.Camera;
import android.media.CamcorderProfile;
import android.media.MediaRecorder;
import android.os.*;
import android.view.*;
import android.view.animation.Animation;
import android.view.animation.AnimationUtils;
import android.widget.*;
import com.googlecode.javacv.*;
import com.phonegap.video.R;

import java.io.File;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

public class VideoRecord extends Activity implements SurfaceHolder.Callback {

    private MediaRecorder m_recorder;
    private SurfaceHolder m_surfaceHolder;
    private CamcorderProfile m_camcorderProfile;
    private Camera m_camera;
    private int m_previewCameraRotationDegree = 0;
    private int m_saveCameraRotationDegree = 0;


    boolean bRecording = false;
    boolean bUsecamera = true;
    boolean bPreviewRunning = false;
    boolean bRevert = true; // true: back camera, false: front camera
    boolean bFocus = false;
    boolean bScreenOrientation = true; // true: portrait, false: landscape

    private SurfaceView m_surfaceview;

    private ProgressBar m_progressbar;

    private LinearLayout m_statusView;
    private LinearLayout m_videoView;
    private LinearLayout m_controlView;

    private ImageView m_imgClose;
    private ImageView m_imgDone;
    private ImageView m_imgRevert;
    private ImageView m_imgRecord;
    private ImageView m_imgFocus;
    private ImageView m_imgviewFocus;

    Animation animationScale;

    int fileIdx = 0;

    int leftTime = 0;
    int duration = 5; // 5sec

    float scale = 0;

    Handler customHandler = new Handler();

    String pre_filename, filename, path;

    ProgressDialog m_prgDialog;

    /**
     * Called when the activity is first created.
     */
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.videorecord);

        getControlVariables();
        initializeUI();

        path= Environment.getExternalStorageDirectory().getAbsolutePath().toString();

        customHandler = new Handler()
        {
            @Override
            public void handleMessage(Message msg)
            {
                if (msg.what == 0)
                {
                    if (!bRecording)
                        return;

                    leftTime ++;
                    if (leftTime <= duration)
                    {
                        m_progressbar.setProgress(leftTime);

                        customHandler.sendEmptyMessageDelayed(0, 1000);
                    }
                    else
                    {
                        try {
                            m_recorder.stop();
                            m_recorder.release();

                            m_camera.release();

                        } catch (IllegalStateException e) {
                            e.printStackTrace();
                            finish();
                        }

                        bRecording = false;

                        m_prgDialog.setMessage("Please wait for saving...");
                        m_prgDialog.setCancelable(false);
                        m_prgDialog.show();

                        new LongOperation().execute("");
                    }
                }
            }
        };

        animationScale = AnimationUtils.loadAnimation(this, R.anim.focus_scale);

        scale = getResources().getDisplayMetrics().density;
    }

    private class LongOperation extends AsyncTask<String, Void, String> {

        @Override
        protected String doInBackground(String... params) {

            try
            {
                mergeVideoFiles();

            } catch (Exception e)
            {

            }

            return "Executed";
        }

        @Override
        protected void onPostExecute(String result) {

            // might want to change "executed" for the returned string passed
            // into onPostExecute() but that is upto you

            m_prgDialog.dismiss();

            m_imgRecord.setImageResource(R.drawable.video_sprites_record_inactive);

            fileIdx = 0;
            leftTime = 0;


            Intent callbackIntent = new Intent();
            callbackIntent.putExtra ("VideoPath", path + "/" + pre_filename + ".mp4");
            setResult(RESULT_OK, callbackIntent);
            finish();


            Intent intent = new Intent(VideoRecord.this, VideoPreview.class);
            intent.putExtra("videoPath", path + "/" + pre_filename + ".mp4");

            if (intent != null)
            {
                startActivity(intent);
            }
        }

        @Override
        protected void onPreExecute() {}

        @Override
        protected void onProgressUpdate(Void... values) {}
    }

    @Override
    protected void onResume() {
        super.onResume();

        initializeUI();
    }

    @Override
    protected void onPause() {
        super.onPause();
    }

    @Override
    protected void onStart() {
        super.onStart();
    }

    @Override
    public void onStop() {
        super.onStop();


    }

    private void getControlVariables()
    {
        m_statusView = (LinearLayout) findViewById(R.id.statusView);
        m_videoView = (LinearLayout) findViewById(R.id.videoView);
        m_controlView = (LinearLayout) findViewById(R.id.controlView);

        m_imgClose = (ImageView) findViewById(R.id.imgClose);
        m_progressbar = (ProgressBar) findViewById(R.id.progressBar);
        m_imgDone = (ImageView) findViewById(R.id.imgDone);

        m_imgRevert = (ImageView) findViewById(R.id.imgRevert);
        m_imgRecord = (ImageView) findViewById(R.id.imgRecord);
        m_imgFocus = (ImageView) findViewById(R.id.imgFocus);

        m_camcorderProfile = CamcorderProfile.get(CamcorderProfile.QUALITY_HIGH);

        m_surfaceview = (SurfaceView) findViewById(R.id.surfaceView);
        m_surfaceHolder = m_surfaceview.getHolder();
        m_surfaceHolder.addCallback(this);
        m_surfaceHolder.setType(SurfaceHolder.SURFACE_TYPE_PUSH_BUFFERS);

        m_imgviewFocus = (ImageView) findViewById(R.id.imgviewFocus);

        m_prgDialog = new ProgressDialog(this);
    }

    private void initializeUI()
    {
        m_imgClose.setOnClickListener(closeClickListener);
        m_imgDone.setOnClickListener(doneClickListener);

        m_imgRevert.setOnClickListener(revertClickListener);
        m_imgRecord.setOnClickListener(recordClickListener);
        m_imgFocus.setOnClickListener(focusClickListener);

        m_progressbar.setMax(duration);
        m_progressbar.setProgress(0);
    }

    @Override
    public void onConfigurationChanged(Configuration newConfig) {
        super.onConfigurationChanged(newConfig);

        if (newConfig.orientation == Configuration.ORIENTATION_PORTRAIT)
        {
            bScreenOrientation = true;

            m_statusView.setPadding(0, (int)(20 * scale + 0.5f), 0, (int)(20 * scale + 0.5f));
            m_controlView.setPadding(0, (int)(30 * scale + 0.5f), 0, (int)(30 * scale + 0.5f));
        }
        else if (newConfig.orientation == Configuration.ORIENTATION_LANDSCAPE)
        {
            bScreenOrientation = false;

            m_statusView.setPadding(0, (int)(5 * scale + 0.5f), 0, (int)(5 * scale + 0.5f));
            m_controlView.setPadding(0, (int)(10 * scale + 0.5f), 0, (int)(10 * scale + 0.5f));
        }

        setCameraRotationDegree();
    }

    private View.OnClickListener closeClickListener = new View.OnClickListener() {
        @Override
        public void onClick(View v) {

            finish();
        }
    };

    private View.OnClickListener doneClickListener = new View.OnClickListener() {
        @Override
        public void onClick(View v) {
        }
    };

    private View.OnClickListener revertClickListener = new View.OnClickListener() {
        @Override
        public void onClick(View v) {

            if (m_camera != null)
            {
                if (bRecording)
                {
                    m_recorder.stop();
                    m_recorder.release();
                }

                m_camera.stopPreview();
                m_camera.release();
                m_camera = null;
            }

            if (bRevert)
            {
                m_camera = Camera.open(Camera.CameraInfo.CAMERA_FACING_FRONT);

                m_imgRevert.setImageResource(R.drawable.video_sprites_revert_inactive);
            }
            else
            {
                m_camera = Camera.open(Camera.CameraInfo.CAMERA_FACING_BACK);

                m_imgRevert.setImageResource(R.drawable.video_sprites_revert);
            }

            bRevert = !bRevert;

            try {
                Camera.Parameters parameters = m_camera.getParameters();

                setCameraRotationDegree();

                m_camera.setDisplayOrientation(m_previewCameraRotationDegree);
                m_camera.setParameters(parameters);
                m_camera.setPreviewDisplay(m_surfaceHolder);
                m_camera.startPreview();
                bPreviewRunning = true;

                if (bRecording)
                {
                    m_recorder = new MediaRecorder();

                    m_camera.unlock();
                    m_recorder.setCamera(m_camera);
                    m_recorder.setOrientationHint(m_saveCameraRotationDegree);
                    //m_recorder.setVideoSize(m_surfaceview.getWidth(), m_surfaceview.getHeight());
                    m_recorder.setPreviewDisplay(m_surfaceHolder.getSurface());
                    m_recorder.setAudioSource(MediaRecorder.AudioSource.DEFAULT);
                    m_recorder.setVideoSource(MediaRecorder.VideoSource.DEFAULT);
                    m_recorder.setProfile(m_camcorderProfile);

                    fileIdx ++;

                    filename = pre_filename + fileIdx + ".mp4";

                    //create empty file it must use
                    File file=new File(path, filename);

                    m_recorder.setOutputFile(path + "/" + filename);

                    try {
                        m_recorder.prepare();

                        m_recorder.start();
                    } catch (IllegalStateException e) {
                        e.printStackTrace();
                        finish();
                    } catch (IOException e) {
                        e.printStackTrace();
                        finish();
                    }

                }

            } catch (IOException e) {
                e.printStackTrace();
            }
        }
    };
    private View.OnClickListener recordClickListener = new View.OnClickListener() {
        @Override
        public void onClick(View v) {

            if (!bRecording)
            {
                prepareRecorder();
                bRecording = true;
                m_recorder.start();

                customHandler.sendEmptyMessageDelayed(0, 1000);

                m_imgRecord.setImageResource(R.drawable.video_sprites_record_active);
            }
            else
            {

                m_recorder.stop();
                m_recorder.release();

                if (bUsecamera) {
                    try {
                        m_camera.reconnect();
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                }

                bRecording = false;

                m_imgRecord.setImageResource(R.drawable.video_sprites_record_inactive);
                m_imgRevert.setImageResource(R.drawable.video_sprites_revert);

            }
        }
    };

    private void mergeVideoFiles() throws Exception, com.googlecode.javacv.FrameRecorder.Exception
    {
        if (fileIdx > 1)
        {
            FrameGrabber grabber1 = new FFmpegFrameGrabber(path + "/" + pre_filename + "1.mp4");
            grabber1.start();

            FrameRecorder recorder = new FFmpegFrameRecorder(path +  "/" + pre_filename + ".mp4", grabber1.getImageWidth(), grabber1.getImageHeight(), grabber1.getAudioChannels());
            recorder.setFrameRate(grabber1.getFrameRate());
            recorder.setSampleFormat(grabber1.getSampleFormat());
            recorder.setSampleRate(grabber1.getSampleRate());
            recorder.start();

            Frame frame1;
            while ((frame1 = grabber1.grabFrame()) != null)
            {
                recorder.record(frame1);
            }

            grabber1.stop();
            File file1 = new File(path + "/" + pre_filename + "1.mp4");
            if (file1.exists())
                file1.delete();


            for (int i = 2; i <= fileIdx; i ++)
            {
                FrameGrabber grabber = new FFmpegFrameGrabber(path + "/" + pre_filename + i + ".mp4");
                grabber.start();

                Frame frame;
                while ((frame = grabber.grabFrame()) != null) {
                    recorder.record(frame);
                }

                grabber.stop();
                File file = new File(path + "/" + pre_filename + i + ".mp4");
                if (file.exists())
                    file.delete();
            }

            recorder.stop();
        }
        else
        {
            pre_filename += fileIdx;
        }
    }

    private View.OnClickListener focusClickListener = new View.OnClickListener() {
        @Override
        public void onClick(View v) {

            if (bFocus)
            {
                m_imgFocus.setImageResource(R.drawable.video_sprites_focus);
                bFocus = false;

                m_surfaceview.setFocusable(false);
                m_surfaceview.setFocusableInTouchMode(false);
            }
            else
            {
                m_imgFocus.setImageResource(R.drawable.video_sprites_focus_inactive);
                bFocus = true;

                m_surfaceview.setFocusable(true);
                m_surfaceview.setFocusableInTouchMode(true);
            }
        }
    };

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        // TODO Auto-generated method stub

        if (!bFocus)
            return true;

        if (m_camera == null)
            return true;

        int action = event.getAction();
        switch(action)
        {
            case MotionEvent.ACTION_DOWN:

                RelativeLayout.LayoutParams param = (RelativeLayout.LayoutParams)m_imgviewFocus.getLayoutParams();
                param.leftMargin = (int)event.getX() - m_imgviewFocus.getWidth() / 2;
                param.topMargin = (int)event.getY() - m_imgviewFocus.getHeight() / 2 - m_videoView.getTop();
                m_imgviewFocus.setLayoutParams(param);

                break;
            case MotionEvent.ACTION_MOVE:
                break;
            case MotionEvent.ACTION_UP:

                m_imgviewFocus.startAnimation(animationScale);

                setAutoFocusArea(m_camera, (int)event.getX(), (int)event.getY(), 128, new Point(m_surfaceview.getWidth(), m_surfaceview.getHeight()));

                m_imgviewFocus.setVisibility(View.INVISIBLE);

                m_camera.autoFocus(myAutoFocusCallback);

                break;
            case MotionEvent.ACTION_CANCEL:
                break;
            case MotionEvent.ACTION_OUTSIDE:
                break;
            default:
        }
        return true; //processed
    }

    Camera.AutoFocusCallback myAutoFocusCallback = new Camera.AutoFocusCallback(){

        @Override
        public void onAutoFocus(boolean arg0, Camera arg1) {
            // TODO Auto-generated method stub
            if (arg0){
                m_camera.cancelAutoFocus();
            }

            float focusDistances[] = new float[3];
            arg1.getParameters().getFocusDistances(focusDistances);
            //prompt.setText("Optimal Focus Distance(meters): " + focusDistances[Camera.Parameters.FOCUS_DISTANCE_OPTIMAL_INDEX]);
        }
    };

    private void setAutoFocusArea(Camera camera, int posX, int posY,
                                  int focusRange, Point point) {

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.ICE_CREAM_SANDWICH) {
            return;
        }

        if (posX < 0 || posY < 0) {
            setArea(m_camera, null);
            return;
        }

        int touchPointX;
        int touchPointY;
        int endFocusY;
        int startFocusY;

        if (bScreenOrientation) {
            touchPointX = point.y >> 1;
            touchPointY = point.x >> 1;

            startFocusY = posX;
            endFocusY   = posY;
        } else {
            touchPointX = point.x >> 1;
            touchPointY = point.y >> 1;

            startFocusY = posY;
            endFocusY = point.x - posX;
        }

        float startFocusX   = 1000F / (float) touchPointY;
        float endFocusX     = 1000F / (float) touchPointX;

        startFocusX = (int) (startFocusX * (float) (startFocusY - touchPointY)) - focusRange;
        startFocusY = (int) (endFocusX * (float) (endFocusY - touchPointX)) - focusRange;
        endFocusX = startFocusX + focusRange;
        endFocusY = startFocusY + focusRange;

        if (startFocusX < -1000)
            startFocusX = -1000;

        if (startFocusY < -1000)
            startFocusY = -1000;

        if (endFocusX > 1000) {
            endFocusX = 1000;
        }

        if (endFocusY > 1000) {
            endFocusY = 1000;
        }

        Rect rect = new Rect((int) startFocusX, (int) startFocusY, (int) endFocusX, (int) endFocusY);
        ArrayList<Camera.Area> arraylist = new ArrayList<Camera.Area>();
        arraylist.add(new Camera.Area(rect, 1000));

        setArea(m_camera, arraylist);
    }

    private void setArea(Camera camera, List<Camera.Area> list) {
        boolean     enableFocusModeMacro = true;

        Camera.Parameters parameters;
        parameters = camera.getParameters();

        int         maxNumFocusAreas    = parameters.getMaxNumFocusAreas();
        int         maxNumMeteringAreas = parameters.getMaxNumMeteringAreas();

        if (maxNumFocusAreas > 0) {
            parameters.setFocusAreas(list);
        }

        if (maxNumMeteringAreas > 0) {
            parameters.setMeteringAreas(list);
        }

        if (list == null || maxNumFocusAreas < 1 || maxNumMeteringAreas < 1) {
            enableFocusModeMacro = false;
        }

        if (enableFocusModeMacro == true) {
            parameters.setFocusMode(Camera.Parameters.FOCUS_MODE_MACRO);
            //Logger.d(TAG, "focus mode macro");
        } else {
            parameters.setFocusMode(Camera.Parameters.FOCUS_MODE_AUTO);
            //Logger.d(TAG, "focus mode auto");
        }
        camera.setParameters(parameters);
    }

    private void prepareRecorder() {
        m_recorder = new MediaRecorder();
        m_recorder.setPreviewDisplay(m_surfaceHolder.getSurface());
        if (bUsecamera) {
            m_camera.unlock();
            m_recorder.setCamera(m_camera);
        }
        m_recorder.setOrientationHint(m_saveCameraRotationDegree);
        //m_recorder.setVideoSize(m_videoView.getWidth(), m_videoView.getHeight());
        //m_recorder.setVideoSize(800, 400);
        m_recorder.setAudioSource(MediaRecorder.AudioSource.DEFAULT);
        m_recorder.setVideoSource(MediaRecorder.VideoSource.DEFAULT);

        m_recorder.setProfile(m_camcorderProfile);

        fileIdx ++;

        if (fileIdx == 1)
            pre_filename =  "VideoRecord" + "" + new SimpleDateFormat("ddMMyyyyHHmmss").format(new Date());

        filename = pre_filename + fileIdx + ".mp4";
        //filename = "VideoRecord" + Build.MODEL + fileIdx +  ".mp4";

        //create empty file it must use
        File file=new File(path, filename);

        m_recorder.setOutputFile(path + "/" + filename);

        try {
            m_recorder.prepare();
        } catch (IllegalStateException e) {
            e.printStackTrace();
            finish();
        } catch (IOException e) {
            e.printStackTrace();
            finish();
        }
    }

    private void setCameraRotationDegree()
    {
        Display display = ((WindowManager)getSystemService(WINDOW_SERVICE)).getDefaultDisplay();

        if (bRevert)
        {
            if(display.getRotation() == Surface.ROTATION_0)
            {
                m_previewCameraRotationDegree = 90;
            }
            else if(display.getRotation() == Surface.ROTATION_90)
            {
                m_previewCameraRotationDegree = 0;
            }
            else if(display.getRotation() == Surface.ROTATION_180)
            {
                m_previewCameraRotationDegree = 90;
            }
            else if(display.getRotation() == Surface.ROTATION_270)
            {
                m_previewCameraRotationDegree = 180;
            }

            m_saveCameraRotationDegree = m_previewCameraRotationDegree;
        }
        else
        {
            if(display.getRotation() == Surface.ROTATION_0)
            {
                m_previewCameraRotationDegree = 90;
                m_saveCameraRotationDegree = 270;
            }
            else if(display.getRotation() == Surface.ROTATION_90)
            {
                m_previewCameraRotationDegree = 0;
                m_saveCameraRotationDegree = 0;
            }
            else if(display.getRotation() == Surface.ROTATION_180)
            {
                m_previewCameraRotationDegree = 90;
                m_saveCameraRotationDegree = 90;
            }
            else if(display.getRotation() == Surface.ROTATION_270)
            {
                m_previewCameraRotationDegree = 180;
                m_saveCameraRotationDegree = 180;
            }
        }
    }

    public void surfaceCreated(SurfaceHolder holder) {
        System.out.println("onsurfacecreated");

        if (bUsecamera) {

            if (bRevert)
            {
                m_camera = Camera.open(Camera.CameraInfo.CAMERA_FACING_BACK);
                m_imgRevert.setImageResource(R.drawable.video_sprites_revert);
            }
            else
            {
                m_camera = Camera.open(Camera.CameraInfo.CAMERA_FACING_FRONT);
                m_imgRevert.setImageResource(R.drawable.video_sprites_revert_inactive);
            }

            try
            {
                //m_camera.stopFaceDetection();
                m_camera.setPreviewDisplay(holder);
                m_camera.startPreview();
                bPreviewRunning = true;
            } catch (IOException e) {
                e.printStackTrace();
            }
        }

    }

    public void surfaceChanged(SurfaceHolder holder, int format, int width,
                               int height) {
        System.out.println("onsurface changed");

        if (!bRecording && bUsecamera) {
            if (bPreviewRunning) {
                m_camera.stopPreview();
            }

            try {
                Camera.Parameters parameters = m_camera.getParameters();

                setCameraRotationDegree();

                m_camera.setDisplayOrientation(m_previewCameraRotationDegree);
                m_camera.setParameters(parameters);
                m_camera.setPreviewDisplay(m_surfaceHolder);
                m_camera.startPreview();
                bPreviewRunning = true;
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
    }

    public void surfaceDestroyed(SurfaceHolder holder) {

        if (bRecording && m_recorder != null)
        {
            m_recorder.stop();
            m_recorder.release();

            bRecording = false;
        }

        if (m_camera != null && bUsecamera)
        {
            m_camera.release();

            bPreviewRunning = false;
        }
    }
}
