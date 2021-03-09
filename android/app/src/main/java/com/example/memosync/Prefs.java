package com.example.memosync;

import android.content.Context;
import android.content.SharedPreferences;
import android.util.Pair;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;

import androidx.preference.PreferenceManager;
import kotlin.reflect.KClass;

public class Prefs {
    static private SharedPreferences prefs;

    static void setupPrefs(Context context){
        if(prefs == null) prefs = PreferenceManager.getDefaultSharedPreferences(context);
    }

    static <T> void setPref(String key, T value){
        SharedPreferences.Editor editor = prefs.edit();
        if(value.getClass() == String.class) editor.putString(key,(String)value);
        if(value.getClass() == Boolean.class) editor.putBoolean(key,(Boolean)value);
        if(value.getClass() == Float.class) editor.putFloat(key,(Float)value);
        if(value.getClass() == Integer.class) editor.putInt(key,(Integer)value);
        if(value.getClass() == Long.class) editor.putLong(key,(Long)value);
        editor.apply();
    }

    static SharedPreferences getPrefs(){
        return prefs;
    }
}
