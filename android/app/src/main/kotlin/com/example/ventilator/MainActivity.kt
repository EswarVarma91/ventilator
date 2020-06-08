package com.example.ventilator

import android.annotation.SuppressLint
import android.app.admin.DevicePolicyManager
import android.app.admin.SystemUpdatePolicy
import android.content.*
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.BatteryManager
import android.os.Build
import android.os.PowerManager
import android.os.UserManager
import android.provider.Settings
import android.util.Log
import android.view.View
import android.view.WindowManager
import androidx.annotation.NonNull
import androidx.annotation.Nullable
import androidx.annotation.RequiresApi
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
    }

    @SuppressLint("InvalidWakeLockTag")
    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        mAdminComponentName = MyDeviceAdminReceiver.getComponentName(this)
        mDevicePolicyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager


        MethodChannel(flutterEngine.getDartExecutor(), CHANNEL).setMethodCallHandler { call, result ->
            if(call.method == "sendPlayAudioStartH"){
                try {
                    mp= MediaPlayer.create(getApplicationContext(),R.raw.high);// the song is a filename which i have pasted inside a folder **raw** created under the **res** folder.//

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
                    mp= MediaPlayer.create(getApplicationContext(),R.raw.medium);// the song is a filename which i have pasted inside a folder **raw** created under the **res** folder.//

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
                    mp= MediaPlayer.create(getApplicationContext(),R.raw.low);// the song is a filename which i have pasted inside a folder **raw** created under the **res** folder.//

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





            else if(call.method == "sendPlayAudioStop"){
                try {
//                    mp= MediaPlayer.create(getApplicationContext(),R.raw.ealarm);// the song is a filename which i have pasted inside a folder **raw** created under the **res** folder.//
                    mp?.stop();
                } catch (ex: Exception) {
                    ex.printStackTrace()
                }
                result.success(true)
            } else if(call.method == "sendsoundoff"){
                try {
//                  //mute audio
                    val amanager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                    amanager.setStreamMute(AudioManager.STREAM_NOTIFICATION, true)
                    amanager.setStreamMute(AudioManager.STREAM_ALARM, true)
                    amanager.setStreamMute(AudioManager.STREAM_MUSIC, true)
                    amanager.setStreamMute(AudioManager.STREAM_RING, true)
                    amanager.setStreamMute(AudioManager.STREAM_SYSTEM, true)
                } catch (ex: Exception) {
                    ex.printStackTrace()
                }
                result.success(true)
            }else if(call.method == "sendsoundon"){
                try {
//                  // unmute audio
                    val amanager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                    amanager.setStreamMute(AudioManager.STREAM_NOTIFICATION, false)
                    amanager.setStreamMute(AudioManager.STREAM_ALARM, false)
                    amanager.setStreamMute(AudioManager.STREAM_MUSIC, false)
                    amanager.setStreamMute(AudioManager.STREAM_RING, false)
                    amanager.setStreamMute(AudioManager.STREAM_SYSTEM, false)
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

        var isAdmin = false
        if (mDevicePolicyManager.isDeviceOwnerApp(packageName)) {
//            Toast.makeText(applicationContext, R.string.device_owner, Toast.LENGTH_SHORT).show()
            isAdmin = true
        } else {
//            Toast.makeText(applicationContext, R.string.not_device_owner, Toast.LENGTH_SHORT).show()
        }
//        setKioskPolicies(true, isAdmin)

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


    @SuppressLint("NewApi")
    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private fun setKioskPolicies(enable: Boolean, isAdmin: Boolean) {
        if (isAdmin) {
            setRestrictions(enable)
            enableStayOnWhilePluggedIn(enable)
            setUpdatePolicy(enable)
            setAsHomeApp(enable)
            setKeyGuardEnabled(enable)
        }
        setLockTask(enable, isAdmin)
        setImmersiveMode(enable)
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private fun setRestrictions(disallow: Boolean) {
        setUserRestriction(UserManager.DISALLOW_SAFE_BOOT, disallow)
        setUserRestriction(UserManager.DISALLOW_FACTORY_RESET, disallow)
        setUserRestriction(UserManager.DISALLOW_ADD_USER, disallow)
        setUserRestriction(UserManager.DISALLOW_USB_FILE_TRANSFER,false)
        setUserRestriction(UserManager.DISALLOW_MOUNT_PHYSICAL_MEDIA, false)
        setUserRestriction(UserManager.DISALLOW_ADJUST_VOLUME, disallow)
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private fun setUserRestriction(restriction: String, disallow: Boolean) = if (disallow) {
        mDevicePolicyManager.addUserRestriction(mAdminComponentName, restriction)
    } else {
        mDevicePolicyManager.clearUserRestriction(mAdminComponentName, restriction)
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private fun enableStayOnWhilePluggedIn(active: Boolean) = if (active) {
        mDevicePolicyManager.setGlobalSetting(mAdminComponentName,
                Settings.Global.STAY_ON_WHILE_PLUGGED_IN,
                Integer.toString(BatteryManager.BATTERY_PLUGGED_AC
                        or BatteryManager.BATTERY_PLUGGED_USB
                        or BatteryManager.BATTERY_PLUGGED_WIRELESS))
    } else {
        mDevicePolicyManager.setGlobalSetting(mAdminComponentName, Settings.Global.STAY_ON_WHILE_PLUGGED_IN, "0")
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private fun setLockTask(start: Boolean, isAdmin: Boolean) {
        if (isAdmin) {
            mDevicePolicyManager.setLockTaskPackages(mAdminComponentName, if (start) arrayOf(packageName) else arrayOf())
        }
        if (start) {
            startLockTask()
        } else {
            stopLockTask()
        }
    }

    @RequiresApi(Build.VERSION_CODES.M)
    private fun setUpdatePolicy(enable: Boolean) {
        if (enable) {
            mDevicePolicyManager.setSystemUpdatePolicy(mAdminComponentName,
                    SystemUpdatePolicy.createWindowedInstallPolicy(60, 120))
        } else {
            mDevicePolicyManager.setSystemUpdatePolicy(mAdminComponentName, null)
        }
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private fun setAsHomeApp(enable: Boolean) {
        if (enable) {
            val intentFilter = IntentFilter(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
                addCategory(Intent.CATEGORY_DEFAULT)
            }
            mDevicePolicyManager.addPersistentPreferredActivity(
                    mAdminComponentName, intentFilter, ComponentName(packageName, MainActivity::class.java.name))
        } else {
            mDevicePolicyManager.clearPackagePersistentPreferredActivities(
                    mAdminComponentName, packageName)
        }
    }

    @RequiresApi(Build.VERSION_CODES.M)
    private fun setKeyGuardEnabled(enable: Boolean) {
        mDevicePolicyManager.setKeyguardDisabled(mAdminComponentName, !enable)
    }

    private fun setImmersiveMode(enable: Boolean) {
        if (enable) {
            val flags = (View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                    or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                    or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                    or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                    or View.SYSTEM_UI_FLAG_FULLSCREEN
                    or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY)
            window.decorView.systemUiVisibility = flags
        } else {
            val flags = (View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                    or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                    or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN)
            window.decorView.systemUiVisibility = flags
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