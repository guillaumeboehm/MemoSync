package com.example.memosync;

import androidx.appcompat.app.AppCompatActivity;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.HashMap;

public class MainActivity extends AppCompatActivity {
    Intent loginActivity;
    Intent memoActivity;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Prefs.setupPrefs(this);
    }

    @Override
    protected void onResume() {
        super.onResume();
        //check if user is saved on device
        checkUser();
        load();
    }

    boolean checkUser(){
        return User.reconnect();
    }

    void load(){
        loginActivity = new Intent(this, LoginActivity.class);
        loginActivity.setFlags(loginActivity.getFlags() | Intent.FLAG_ACTIVITY_NO_HISTORY);
        memoActivity = new Intent(this, MemoActivity.class);
        memoActivity.setFlags(memoActivity.getFlags() | Intent.FLAG_ACTIVITY_NO_HISTORY);

        if(User.isConnected())
            loadMemo();
        else
            loadLogin();
    }

    void loadLogin(){
        startActivity(loginActivity);
    }

    void loadMemo(){
        startActivity(memoActivity);
    }
}