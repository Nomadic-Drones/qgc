package org.mavlink.qgroundcontrol;

import java.io.IOException;

import android.app.Activity;
import android.app.WallpaperManager;
import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Matrix;
import android.graphics.Paint;
import android.util.DisplayMetrics;
import android.util.Log;

public class WallpaperSetup {
    private static final String TAG = "WallpaperSetup";
    private static final String PREF_KEY = "wallpaper_set_v1";

    public static void applyOnce(Activity activity) {
        SharedPreferences prefs = activity.getSharedPreferences("NomadicControl", Context.MODE_PRIVATE);
        if (prefs.getBoolean(PREF_KEY, false)) {
            return;
        }

        try {
            DisplayMetrics metrics = new DisplayMetrics();
            activity.getWindowManager().getDefaultDisplay().getRealMetrics(metrics);
            int screenW = metrics.widthPixels;
            int screenH = metrics.heightPixels;

            Bitmap src = BitmapFactory.decodeResource(activity.getResources(), R.drawable.nomadic_wallpaper);
            if (src == null) {
                Log.e(TAG, "Failed to decode wallpaper resource");
                return;
            }

            // Scale to cover the screen (center-crop)
            float scale = Math.max((float) screenW / src.getWidth(), (float) screenH / src.getHeight());
            int scaledW = Math.round(src.getWidth() * scale);
            int scaledH = Math.round(src.getHeight() * scale);

            Bitmap result = Bitmap.createBitmap(screenW, screenH, Bitmap.Config.ARGB_8888);
            Canvas canvas = new Canvas(result);
            Paint paint = new Paint(Paint.FILTER_BITMAP_FLAG);
            float dx = (screenW - scaledW) / 2f;
            float dy = (screenH - scaledH) / 2f;
            Matrix matrix = new Matrix();
            matrix.setScale(scale, scale);
            matrix.postTranslate(dx, dy);
            canvas.drawBitmap(src, matrix, paint);
            src.recycle();

            WallpaperManager.getInstance(activity).setBitmap(result);
            result.recycle();

            prefs.edit().putBoolean(PREF_KEY, true).apply();
            Log.i(TAG, "Wallpaper set successfully (" + screenW + "x" + screenH + ")");
        } catch (IOException e) {
            Log.e(TAG, "Failed to set wallpaper", e);
        }
    }
}
