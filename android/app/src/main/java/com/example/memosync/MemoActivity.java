package com.example.memosync;

import androidx.appcompat.app.ActionBar;
import androidx.appcompat.app.AppCompatActivity;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.PorterDuff;
import android.inputmethodservice.Keyboard;
import android.os.Build;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.util.Log;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.View;
import android.view.WindowManager;
import android.view.inputmethod.InputMethodManager;
import android.widget.Button;
import android.widget.Toast;

import com.google.android.material.textfield.TextInputLayout;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.concurrent.Callable;


public class MemoActivity extends AppCompatActivity {

    //TODO refresh to pull memo
    //TODO Hide keyboard on click on nothing

    public Intent mainActivity;

    public TextInputLayout memo;
    public Button LogoutButton;
    public Button SaveButton;

    public String prevMemo=null;
    public String memoBeingSaved;
    public boolean promptNextSave = true;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.memo_page);
        mainActivity = new Intent(this, MainActivity.class);

        memo = (TextInputLayout) findViewById(R.id.memo);
        LogoutButton = (Button) findViewById(R.id.logout_button);
        SaveButton = (Button) findViewById(R.id.save_button);

        ActionBar ab = getSupportActionBar();
        ab.setTitle("AAAAAAAAAAH");

        memo.getEditText().addTextChangedListener(new TextWatcher() {
            @Override public void beforeTextChanged(CharSequence charSequence, int i, int i1, int i2) {}
            @Override public void afterTextChanged(Editable editable) {}
            @Override
            public void onTextChanged(CharSequence charSequence, int i, int i1, int i2) {
                if(prevMemo != null && !memo.getEditText().getText().toString().equals(prevMemo))
                    SaveButton.setVisibility(View.VISIBLE);
                else
                    SaveButton.setVisibility(View.GONE);
            }
        });
        LogoutButton.setOnClickListener(v -> {
            User.disconnect();
            startActivity(mainActivity);
        });
        SaveButton.setOnClickListener(v -> {
            hideKeyboard();
            hideCursor();
            saveMemo();
        });

        try{
            HttpRequest req = new HttpRequest(this);
            req.execute(ApiCalls.getMemoUrl(User.getCurrentUser()));

            memo.setHint(getString(R.string.PREF_MEMO_HINT) + User.getCurrentUser() + getString(R.string.SUF_MEMO_HINT));
        } catch(Exception e){
            Log.e("HttpRequest",e.getClass().getSimpleName() + " in Activity onCreate " + e.getMessage() + '\n' + Log.getStackTraceString(e));
        }
    }
    @Override
    protected void onDestroy() {
        super.onDestroy();
        //TODO If save on quit pref is on
        saveMemo(false);
    }

    public void saveMemo(boolean... prompt){
        if(prompt.length > 0) promptNextSave = prompt[0]; else promptNextSave = true; // prompts by default
        memoBeingSaved = memo.getEditText().getText().toString();
        HttpRequest req = new HttpRequest(this);
        req.execute(ApiCalls.getSaveMemoUrl(User.getCurrentUser(),memoBeingSaved));
    }

    public void httpResponse(JSONObject response_json){
        try {
            if(response_json.has("error")){
                //error handling
            }
            else if(response_json.has("memo")){
                prevMemo = response_json.getString("memo");
                memo.getEditText().setText(response_json.getString("memo"));
            }
            else if(response_json.has("success")){
                // show good job
                if(promptNextSave)
                    Toast.makeText(getApplicationContext(),getString(getResources().getIdentifier(response_json.getString("success"),"string",this.getPackageName())),Toast.LENGTH_SHORT).show();
                prevMemo = memoBeingSaved;
                SaveButton.setVisibility(View.GONE);
            }
        } catch (JSONException e) {e.printStackTrace();}
    }

    void hideKeyboard(){
        InputMethodManager imm = (InputMethodManager) getApplicationContext().getSystemService(Activity.INPUT_METHOD_SERVICE);
        imm.hideSoftInputFromWindow(memo.getEditText().getWindowToken(),0);
    }
    void hideCursor(){
        memo.clearFocus();
    }
}