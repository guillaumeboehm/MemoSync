package com.example.memosync;

import androidx.appcompat.app.AppCompatActivity;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;

public class MainActivity extends AppCompatActivity {
    Intent loginActivity;
    Intent memoActivity;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        User.context = this;
    }

    @Override
    protected void onResume() {
        super.onResume();
        //check is user is saved on device
        checkUser();
        load();
    }

    boolean checkUser(){
        //check localStorage
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