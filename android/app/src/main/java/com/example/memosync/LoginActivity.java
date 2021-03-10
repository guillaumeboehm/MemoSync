package com.example.memosync;

import androidx.appcompat.app.AppCompatActivity;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.util.Log;
import android.view.MotionEvent;
import android.view.View;
import android.view.inputmethod.InputMethodManager;
import android.widget.Button;

import com.google.android.material.textfield.TextInputLayout;

import org.json.JSONException;
import org.json.JSONObject;


public class LoginActivity extends AppCompatActivity {

    public Intent mainActivity;

    public Button login_button;
    public Button register_button;
    public TextInputLayout login_input;

    @SuppressLint("ClickableViewAccessibility")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.login_page);
        mainActivity = new Intent(this, MainActivity.class);

        login_button = findViewById(R.id.login_button);
        register_button = findViewById(R.id.create_button);
        login_input = findViewById(R.id.login_input);

        findViewById(R.id.main_login_container).setOnTouchListener((View v, @SuppressLint("ClickableViewAccessibility") MotionEvent event) -> {
            if(event.getAction() == MotionEvent.ACTION_DOWN){
                hideCursor();hideKeyboard();
                return true;
            }
            return false;
        });

        // call login on button click
        login_button.setOnClickListener(v ->{
                tryLogin(login_input.getEditText().getText().toString());
            });
        register_button.setOnClickListener(v ->{
                tryCreate(login_input.getEditText().getText().toString());
            });

        // call login on editText enter
        login_input.getEditText().setOnEditorActionListener((view,actionId,event) -> {
                tryLogin(login_input.getEditText().getText().toString());
                return false;
            });

        // Listens for edit text changes to hide the create user button
        login_input.getEditText().addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence charSequence, int i, int i1, int i2) {}
            @Override
            public void onTextChanged(CharSequence charSequence, int i, int i1, int i2) {
                // text changed so hide the create user button
                register_button.setVisibility(View.GONE);
                hideError();
            }
            @Override
            public void afterTextChanged(Editable editable) {}
        });

        VolleyRequest.request(ApiCalls.postMemoUrl(),
                            ApiCalls.postMemoParams(""),
                            response -> {
                                Log.d("---------------",response.toString());
                            },
                            this);
    }

    void tryLogin(String userName){
        if(userName != "") {
            VolleyRequest.request(ApiCalls.postMemoUrl(),
                                ApiCalls.postMemoParams(userName),
                                this::httpResponse,
                                this);
        }
    }

    void httpResponse(JSONObject response_feed){
        if(response_feed.has("error")){
            // error handling
            try {
                printError(getString(getResources().getIdentifier(response_feed.getString("error"),"string",this.getPackageName())));
                register_button.setVisibility(View.VISIBLE);
            } catch (JSONException e) {e.printStackTrace();}
        }
        else if(response_feed.has("memo")){
            // eyy connect
            User.connect(login_input.getEditText().getText().toString());
            startActivity(mainActivity);
        }
        else if(response_feed.has("new_user")){
            try {
                // If the user has been created connect to it
                tryLogin(response_feed.getString("new_user"));
            } catch (JSONException e) {e.printStackTrace();}
        }
    }

    void tryCreate(String userName){
        VolleyRequest.request(ApiCalls.postCreateUserUrl(),
                            ApiCalls.postCreateUserParams(userName),
                            this::httpResponse,
                            this);
    }

    // Error displays
    void printError(String msg){
        login_input.setError(msg);
    }
    void hideError(){
        login_input.setError("");
    }

    void hideKeyboard(){
        InputMethodManager imm = (InputMethodManager) getApplicationContext().getSystemService(Activity.INPUT_METHOD_SERVICE);
        imm.hideSoftInputFromWindow(login_input.getEditText().getWindowToken(),0);
    }
    void hideCursor(){
        login_input.clearFocus();
    }
}