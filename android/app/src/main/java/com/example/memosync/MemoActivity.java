package com.example.memosync;

import androidx.appcompat.app.AppCompatActivity;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.Toast;

import com.google.android.material.textfield.TextInputLayout;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.concurrent.Callable;


public class MemoActivity extends AppCompatActivity {

    //TODO refresh to pull memo
    //TODO Hide save button when no changes have been made

    public Intent mainActivity;

    public TextInputLayout memo;
    public Button LogoutButton;
    public Button SaveButton;

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
                //TODO Hide keyboard
                HttpRequest req = new HttpRequest(this);
                req.execute(ApiCalls.getSaveMemoUrl(User.getCurrentUser(),memo.getEditText().getText().toString()));
            });

        try{
            HttpRequest req = new HttpRequest(this);
            req.execute(ApiCalls.getMemoUrl(User.getCurrentUser()));

            memo.setHint(getString(R.string.PREF_MEMO_HINT) + User.getCurrentUser() + getString(R.string.SUF_MEMO_HINT));
        } catch(Exception e){
            Log.e("HttpRequest",e.getClass().getSimpleName() + " in Activity onCreate " + e.getMessage() + '\n' + Log.getStackTraceString(e));
        }
    }

    public void httpResponse(JSONObject response_json){
        try {
            if(response_json.has("error")){
                //error handling
            }
            else if(response_json.has("memo")){
                memo.getEditText().setText(response_json.getString("memo"));
            }
            else if(response_json.has("success")){
                // show good job
                Toast.makeText(getApplicationContext(),getString(getResources().getIdentifier(response_json.getString("success"),"string",this.getPackageName())),Toast.LENGTH_LONG).show();
            }
        } catch (JSONException e) {e.printStackTrace();}
    }
}