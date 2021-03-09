package com.example.memosync;

import android.content.Context;

public class User {
    static private String current_user = "";
    static public boolean connected = false;

    static boolean isConnected(){
        return connected;
    }

    static String getCurrentUser(){ return current_user; }

    static void disconnect(){ connected = false; Prefs.setPref("user","");}

    static boolean connect(String userName){
        current_user = userName;
        connected = true;
        Prefs.setPref("user",current_user);
        return connected;
    }

    // returns true if was connected
    static boolean reconnect(){
        String userName = Prefs.getPrefs().getString("user","");
        if(userName != null && userName != "")
            return connect(userName);
        return false;
    }
}
