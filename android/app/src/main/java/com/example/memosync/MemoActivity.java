package com.example.memosync;

import androidx.appcompat.app.AppCompatActivity;

import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.Button;

import com.google.android.material.textfield.TextInputLayout;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;

public class MemoActivity extends AppCompatActivity {

    String state = "login";
    final String getMemoUrl = "https://yorokobii.ovh/api/?user=bruh";


    TextInputLayout memo;
    Button LogoutButton;
    Button SaveButton;
    Button test;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        loadMemo();
    }

    void loadLogin(){
        setContentView(R.layout.login_page);
        test = (Button) findViewById(R.id.button);

        test.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                loadMemo();
            }
        });
    }

    void loadMemo(){
        setContentView(R.layout.activity_main);

        memo = (TextInputLayout) findViewById(R.id.memo);
        LogoutButton = (Button) findViewById(R.id.logout_button);
        SaveButton = (Button) findViewById(R.id.save_button);

        memo.setHint("Your memo :");
        try{

            LogoutButton.setOnClickListener(new View.OnClickListener() {
                public void onClick(View v) {
                    memo.setVisibility(View.GONE);
                    loadLogin();
                }
            });
            SaveButton.setOnClickListener(new View.OnClickListener() {
                public void onClick(View v) {
                    memo.setVisibility(View.VISIBLE);
                }
            });

            HttpRequest req = new HttpRequest(memo);
            req.execute(getMemoUrl);

        } catch(Exception e){
            Log.e("HttpRequest",e.getClass().getSimpleName() + " in Activity onCreate " + e.getMessage() + '\n' + Log.getStackTraceString(e));
        }
    }
}