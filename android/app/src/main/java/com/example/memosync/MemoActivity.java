package com.example.memosync;

import androidx.appcompat.app.AppCompatActivity;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.Button;

import com.google.android.material.textfield.TextInputLayout;


public class MemoActivity extends AppCompatActivity {

    Intent mainActivity;

    TextInputLayout memo;
    Button LogoutButton;
    Button SaveButton;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.memo_page);
        mainActivity = new Intent(this, MainActivity.class);

        memo = (TextInputLayout) findViewById(R.id.memo);
        LogoutButton = (Button) findViewById(R.id.logout_button);
        SaveButton = (Button) findViewById(R.id.save_button);

        LogoutButton.setOnClickListener(v -> {
                User.disconnect();
                startActivity(mainActivity);
            });
        SaveButton.setOnClickListener(v -> {
                User.disconnect();
                startActivity(mainActivity);
            });

        try{
            HttpRequest req = new HttpRequest(memo);
            req.execute(ApiCalls.getMemoUrl("bruh"));
        } catch(Exception e){
            Log.e("HttpRequest",e.getClass().getSimpleName() + " in Activity onCreate " + e.getMessage() + '\n' + Log.getStackTraceString(e));
        }
    }
}