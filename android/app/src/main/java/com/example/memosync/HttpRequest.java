package com.example.memosync;

import android.app.Activity;
import android.os.AsyncTask;

import com.google.android.material.textfield.TextInputLayout;

import org.json.JSONException;
import org.json.JSONObject;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.URL;
import java.util.concurrent.Callable;

class HttpRequest extends AsyncTask<String, Void, String> {

    private Exception exception;
    private Activity parent_activity;

    HttpRequest(Activity activity){
        this.parent_activity = activity;
    }

    protected String doInBackground(String... urls) {
        try {
            URL url = new URL(urls[0]);
            String ret;

            try(BufferedReader br = new BufferedReader(
              new InputStreamReader(url.openStream(), "utf-8"))) {
                StringBuilder response = new StringBuilder();
                String responseLine = null;
                while ((responseLine = br.readLine()) != null) {
                    response.append(responseLine.trim());
                }
                ret = response.toString();
            }
            return ret;
        } catch (Exception e) {
            this.exception = e;
            return null;
        }
    }

    protected void onPostExecute(String feed) {
        // TODO: check this.exception
        // TODO: do something with the feed
        try {
            if(this.parent_activity.getClass() == MemoActivity.class) {
                MemoActivity memo_activity = ((MemoActivity) this.parent_activity);
                memo_activity.httpResponse(new JSONObject(feed));
            }
            else if(this.parent_activity.getClass() == LoginActivity.class){
                LoginActivity login_activity = ((LoginActivity) this.parent_activity);
                login_activity.httpResponse(new JSONObject(feed));
            }
        } catch (JSONException e){ e.printStackTrace(); }
    }
}