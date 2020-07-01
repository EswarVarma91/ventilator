package com.example.ventilator

import android.Manifest
import android.annotation.SuppressLint
import android.app.admin.DevicePolicyManager
import android.content.*
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.BatteryManager
import android.os.Build
import android.os.PowerManager
import android.util.Log
import androidx.annotation.NonNull
import androidx.annotation.Nullable
import androidx.annotation.RequiresApi
import com.example.ventilator.util.DownloadController
import com.nabinbhandari.android.permissions.PermissionHandler
import com.nabinbhandari.android.permissions.Permissions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant


class MainActivity: FlutterActivity() {

    private lateinit var mAdminComponentName: ComponentName
    private lateinit var mDevicePolicyManager: DevicePolicyManager
    var mp: MediaPlayer? = null
    private val mPowerManager: PowerManager? = null
    private var mWakeLock: PowerManager.WakeLock? = null
    val RESULT_ENABLE = 1

    companion object {
        const val LOCK_ACTIVITY_KEY = "MainActivity"
        const val CHANNEL = "shutdown"
        const val PERMISSION_REQUEST_STORAGE = 0
    }
    lateinit var downloadController: DownloadController
//    val apkUrl = "https://eagleaspect.com:9000/static/apks/v1.7.5.apk"
    val apkUrl = "https://eagleaspect.com:9000/static/apks/"

    @SuppressLint("InvalidWakeLockTag")
    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)

//
        mAdminComponentName = MyDeviceAdminReceiver.getComponentName(this)
        mDevicePolicyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager


        MethodChannel(flutterEngine.getDartExecutor(), CHANNEL).setMethodCallHandler { call, result ->

            val params = call.arguments as? Map<String, Any>



            if(call.method == "sendPlayAudioStartH"){
                try {
                    mp= MediaPlayer.create(getApplicationContext(), R.raw.high);// the song is a filename which i have pasted inside a folder **raw** created under the **res** folder.//

                    if(mp?.isPlaying()!!){
//                        mp?.stop();
//                        mp?.reset();
//                        mp?.release();
                    }
                    else{
                        mp?.start()
                        mp?.setLooping(true)
                        mp!!.setOnCompletionListener(object : MediaPlayer.OnCompletionListener {
                            override fun onCompletion(mp: MediaPlayer) {
                                mp?.release()

                            }
                        })
                    }
                } catch (ex: Exception) {
                    ex.printStackTrace()
                }
                result.success(true)
            }  else if(call.method == "sendPlayAudioStartM"){
                try {
                    mp= MediaPlayer.create(getApplicationContext(), R.raw.medium);// the song is a filename which i have pasted inside a folder **raw** created under the **res** folder.//

                    if(mp?.isPlaying()!!){
//                        mp?.stop();
//                        mp?.reset();
//                        mp?.release();
                    }
                    else{
                        mp?.start()
                        mp?.setLooping(true)
                        mp!!.setOnCompletionListener(object : MediaPlayer.OnCompletionListener {
                            override fun onCompletion(mp: MediaPlayer) {
                                mp?.release()

                            }
                        })
                    }
                } catch (ex: Exception) {
                    ex.printStackTrace()
                }
                result.success(true)
            }else if(call.method == "sendPlayAudioStartL"){
                try {
                    mp= MediaPlayer.create(getApplicationContext(), R.raw.low);// the song is a filename which i have pasted inside a folder **raw** created under the **res** folder.//

                    if(mp?.isPlaying()!!){
//                        mp?.stop();
//                        mp?.reset();
//                        mp?.release();
                    }
                    else{
                        mp?.start()
                        mp?.setLooping(true)
                        mp!!.setOnCompletionListener(object : MediaPlayer.OnCompletionListener {
                            override fun onCompletion(mp: MediaPlayer) {
                                mp?.release()

                            }
                        })
                    }
                } catch (ex: Exception) {
                    ex.printStackTrace()
                }
                result.success(true)
            }else  if (call.method == "turnOnScreen") {
                try {
                    Log.v("ProximityActivity", "ON!")
                    mWakeLock = mPowerManager?.newWakeLock(PowerManager.SCREEN_BRIGHT_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP or PowerManager.FULL_WAKE_LOCK, "tag")
                    mWakeLock?.acquire()
//                    getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);


                } catch (ex: Exception) {
                    ex.printStackTrace()
                }
                result.success(true)
            }
            else  if (call.method == "turnOffScreen") {
                try {
//                    val proc = Runtime.getRuntime().exec(arrayOf("su", "-c", "reboot -p"))
//                    proc.waitFor()
                    Log.v("ProximityActivity", "OFF!");
                    if(mDevicePolicyManager.isAdminActive(mAdminComponentName)){
                        mDevicePolicyManager.lockNow()
                    }else{
                        val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
                        intent.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, mAdminComponentName)
                        intent.putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, "Please Click On Activate")
                        startActivityForResult(intent, RESULT_ENABLE)
                    }
//                    mWakeLock = mPowerManager?.newWakeLock(PowerManager.PROXIMITY_SCREEN_OFF_WAKE_LOCK, "tag");
//                    mWakeLock?.acquire();
                    finish()
//                  System.exit(0)
                } catch (ex: Exception) {
                    ex.printStackTrace()
                }
                result.success(true)
            }
            else if(call.method == "checkforUpdates"){
//                print(params?.get("from")as String);
                try {
                    downloadController = DownloadController(this, params?.get("urlFlutter") as String)
//                    downloadController = DownloadController(this, apkUrl)
                    // check storage permission granted if yes then start downloading file
                    Permissions.check(this /*context*/, Manifest.permission.WRITE_EXTERNAL_STORAGE, null, object : PermissionHandler() {
                        override fun onGranted() {
                            downloadController.enqueueDownload()
                        }
                    })
                } catch (ex: Exception) {
                    ex.printStackTrace()
                }
                result.success(true)
            }

            else if(call.method == "sendPlayAudioStop"){
                try {
//                    mp= MediaPlayer.create(getApplicationContext(),R.raw.ealarm);// the song is a filename which i have pasted inside a folder **raw** created under the **res** folder.//
                    if(mp?.isPlaying()!!){
                        mp?.stop();
//                        mp?.reset();
//                        mp?.release();
                    }
                } catch (ex: Exception) {
                    ex.printStackTrace()
                }
                result.success(true)
            } else if(call.method == "sendsoundoff"){
                try {
//                  //mute audio
                    val amanager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                    // Change the stream to your stream of choice.
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M){
                        amanager.adjustStreamVolume(AudioManager.STREAM_MUSIC, AudioManager.ADJUST_MUTE, 0);
                        amanager.adjustStreamVolume(AudioManager.STREAM_NOTIFICATION, AudioManager.ADJUST_MUTE, 0)
                        amanager.adjustStreamVolume(AudioManager.STREAM_ALARM, AudioManager.ADJUST_MUTE, 0)
                        amanager.adjustStreamVolume(AudioManager.STREAM_RING, AudioManager.ADJUST_MUTE, 0)
                        amanager.adjustStreamVolume(AudioManager.STREAM_SYSTEM, AudioManager.ADJUST_MUTE, 0)
                    } else {
                        amanager.setStreamMute(AudioManager.STREAM_MUSIC, true);
                        amanager.setStreamMute(AudioManager.STREAM_NOTIFICATION, true)
                        amanager.setStreamMute(AudioManager.STREAM_ALARM, true)
                        amanager.setStreamMute(AudioManager.STREAM_RING, true)
                        amanager.setStreamMute(AudioManager.STREAM_SYSTEM, true)
                    }
                } catch (ex: Exception) {
                    ex.printStackTrace()
                }
                result.success(true)
            }else if(call.method == "sendsoundon"){
                try {
//                  // unmute audio
                    val amanager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                    amanager.setStreamVolume(AudioManager.STREAM_MUSIC, amanager.getStreamMaxVolume(AudioManager.STREAM_MUSIC), 0)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M){
                        amanager.adjustStreamVolume(AudioManager.STREAM_MUSIC, AudioManager.ADJUST_UNMUTE, 0);
                        amanager.adjustStreamVolume(AudioManager.STREAM_NOTIFICATION, AudioManager.ADJUST_UNMUTE, 0)
                        amanager.adjustStreamVolume(AudioManager.STREAM_ALARM, AudioManager.ADJUST_UNMUTE, 0)
                        amanager.adjustStreamVolume(AudioManager.STREAM_RING, AudioManager.ADJUST_UNMUTE, 0)
                        amanager.adjustStreamVolume(AudioManager.STREAM_SYSTEM, AudioManager.ADJUST_UNMUTE, 0)
                    } else {
                        amanager.setStreamMute(AudioManager.STREAM_MUSIC, false);
                        amanager.setStreamMute(AudioManager.STREAM_NOTIFICATION, false)
                        amanager.setStreamMute(AudioManager.STREAM_ALARM, false)
                        amanager.setStreamMute(AudioManager.STREAM_RING, false)
                        amanager.setStreamMute(AudioManager.STREAM_SYSTEM, false)
                    }
                } catch (ex: Exception) {
                    ex.printStackTrace()
                }
                result.success(true)
            }else if (call.method == "getBatteryLevel") {
                val batteryLevel = getBatteryLevel()

                if (batteryLevel != -1) {
                    result.success(batteryLevel)
                } else {
                    result.error("UNAVAILABLE", "Battery level not available.", null)
                }
            } else {
                result.notImplemented()
            }
        }

    }





    private fun getBatteryLevel(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
            batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        } else {
            val intent = ContextWrapper(applicationContext).registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
            intent!!.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) * 100 / intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, @Nullable data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == RESULT_ENABLE) {
//            if (resultCode == Activity.RESULT_OK) {
//
//            } else {
            finish()
            System.exit(0)
            //            }
            return
        }
    }

}