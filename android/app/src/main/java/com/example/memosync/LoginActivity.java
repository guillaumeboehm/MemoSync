package com.example.memosync;

import androidx.appcompat.app.AppCompatActivity;

import android.content.Intent;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.util.Log;
import android.view.KeyEvent;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;

import com.google.android.material.textfield.TextInputLayout;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;


public class LoginActivity extends AppCompatActivity {

    //TODO Click outside hides keyboard and cursor

    public Intent mainActivity;

    public Button login_button;
    public Button register_button;
    public TextInputLayout login_input;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.login_page);
        mainActivity = new Intent(this, MainActivity.class);

        login_button = (Button) findViewById(R.id.login_button);
        register_button = (Button) findViewById(R.id.create_button);
        login_input = (TextInputLayout) findViewById(R.id.login_input);

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
    }

    // Calls the HttpRequest
    void tryLogin(String userName){
        if(userName != "") {
            HttpRequest req = new HttpRequest(this);
            req.execute(ApiCalls.getMemoUrl(userName));
        }
    }

    // called by the HttpRequest if user exists
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

    // Calls the HttpRequest
    void tryCreate(String userName){
        HttpRequest req = new HttpRequest(this);
        req.execute(ApiCalls.getCreateUserUrl(login_input.getEditText().getText().toString()));
    }

    // Error displays
    void printError(String msg){
        login_input.setError(msg);
    }
    void hideError(){
        login_input.setError("");
    }
}