package com.example.memosync;

import android.content.Context;

import org.json.JSONException;
import org.json.JSONObject;

public class User {
    static public Context context;
    static private String current_user = "";
    static public boolean connected = false;

    static boolean isConnected(){
        return connected;
    }

    static String getCurrentUser(){ return current_user; }

    static void disconnect(){ connected = false; ConfigFile.set("user","",context); }

    static void connect(){ connect(context.getString(R.string.DEBUG_USERNAME)); } //DEBUG PURPOSES

    static boolean connect(String userName){
        current_user = userName;
        connected = true;
        ConfigFile.set("user",current_user,context);
        return connected;
    }

    // returns true if was connected
    static boolean reconnect(){
        JSONObject conf = ConfigFile.getJson(context);
        try {
            if(conf.has("user") && !conf.getString("user").equals(""))
                return connect(conf.getString("user"));
        } catch (JSONException e) {e.printStackTrace();}
        return false;
    }
}
