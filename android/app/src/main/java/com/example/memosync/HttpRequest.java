package com.example.memosync;

import android.app.Activity;
import android.os.AsyncTask;
import android.util.Log;

import com.google.android.material.textfield.TextInputLayout;

import org.json.JSONException;
import org.json.JSONObject;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.HashMap;
import java.util.concurrent.Callable;

import javax.net.ssl.HttpsURLConnection;

class HttpRequest extends AsyncTask<String, Void, String> {

    private Exception exception;
    private final Activity parent_activity;

    HttpRequest(Activity activity){
        parent_activity = activity;
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

    public String performPostCall(String requestURL,
                                  HashMap<String, String> postDataParams) {

        URL url;
        String response = "";
        try {
            url = new URL(requestURL);

            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
                conn.setReadTimeout(this.parent_activity.getResources().getInteger(
                        R.integer.maximum_timeout_to_server));
                conn.setConnectTimeout(this.parent_activity.getResources().getInteger(
                        R.integer.maximum_timeout_to_server));
                conn.setRequestMethod("POST");
                conn.setDoInput(true);
                conn.setDoOutput(true);

                conn.setRequestProperty("Content-Type", "application/json");

            Log.e("performPostCall", "11 - url : " + requestURL);

            /*
             * JSON
             */

            JSONObject root = new JSONObject();

            //root.put("securityInfo", Static.getSecurityInfo(context));
            //root.put("advertisementId", advertisementId);

            Log.e("performPostCall", "12 - root : " + root.toString());

            String str = root.toString();
            byte[] outputBytes = str.getBytes("UTF-8");
            OutputStream os = conn.getOutputStream();
            os.write(outputBytes);

            int responseCode = conn.getResponseCode();

            Log.e("performPostCall", "13 - responseCode : " + responseCode);

            if (responseCode == HttpsURLConnection.HTTP_OK) {
                Log.e("performPostCall", "14 - HTTP_OK");

                String line;
                BufferedReader br = new BufferedReader(new InputStreamReader(
                        conn.getInputStream()));
                while ((line = br.readLine()) != null) {
                    response += line;
                }
            } else {
                Log.e("performPostCall", "14 - False - HTTP_OK");
                response = "";
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        return response;
    }
}