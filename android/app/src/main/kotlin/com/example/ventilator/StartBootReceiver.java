package com.example.ventilator;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

public class StartBootReceiver extends BroadcastReceiver {

    private static final String TAG = StartBootReceiver.class.getSimpleName();

    @Override
    public void onReceive(Context context, Intent intent) {
        Log.i(TAG, "BOOT detected");
        if (Intent.ACTION_BOOT_COMPLETED.equals(intent.getAction())) {
            Intent mIntent = new Intent(context, MainActivity.class);
            mIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            context.startActivity(mIntent);
        }
    }
}
