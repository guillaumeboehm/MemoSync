package com.example.memosync;

import androidx.appcompat.app.AppCompatActivity;

import android.content.Intent;
import android.os.Bundle;
import android.widget.Button;

import com.google.android.material.textfield.TextInputLayout;


public class LoginActivity extends AppCompatActivity {

    Button login_button;
    TextInputLayout login_input;
    Intent mainActivity;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.login_page);
        mainActivity = new Intent(this, MainActivity.class);

        login_button = (Button) findViewById(R.id.login_button);
        login_input = (TextInputLayout) findViewById(R.id.login_input);

        login_button.setOnClickListener(v ->{
                User.connect(login_input.getEditText().getText().toString());
                startActivity(mainActivity);
            });
    }
}