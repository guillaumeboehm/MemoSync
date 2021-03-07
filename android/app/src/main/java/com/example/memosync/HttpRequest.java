package com.example.memosync;

import android.os.AsyncTask;

import com.google.android.material.textfield.TextInputLayout;

import org.json.JSONException;
import org.json.JSONObject;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.URL;

class HttpRequest extends AsyncTask<String, Void, String> {

    private Exception exception;
    private String lastData;
    private TextInputLayout memo;

    HttpRequest(TextInputLayout _memo){
        this.memo = _memo;
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
                System.out.println(response.toString());
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
        lastData = feed;
        try {
            memo.getEditText().setText(new JSONObject(feed).getString("memo"));
        } catch (JSONException e){ e.printStackTrace(); }
    }

    public String getLastDate(){
        return lastData;
    }
}