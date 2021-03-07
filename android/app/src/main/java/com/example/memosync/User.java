package com.example.memosync;

import android.content.Context;

public class User {
    static public Context context;
    static private String current_user;
    static public boolean connected = false;

    static boolean isConnected(){
        return connected;
    }

    static void disconnect(){ connected = false; }

    static void connect(){ current_user = context.getString(R.string.DEBUG_USERNAME); connected = true; } //DEBUG PURPOSES

    static void connect(String userName){



        current_user = userName;
        connected = true;
    }
}
