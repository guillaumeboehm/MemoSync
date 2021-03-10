package com.example.memosync;

import android.content.Context;

import com.android.volley.Request;
import com.android.volley.RequestQueue;
import com.android.volley.Response;
import com.android.volley.toolbox.JsonObjectRequest;
import com.android.volley.toolbox.Volley;

import org.json.JSONObject;

import java.util.HashMap;

public class VolleyRequest {
    static void request(String url, HashMap<String,String> postParams, Response.Listener<JSONObject> responseListener, Context context){
        JSONObject parameters;
        parameters = new JSONObject(postParams);

        JsonObjectRequest jsonRequest = new JsonObjectRequest(Request.Method.POST, url, parameters, responseListener, Throwable::printStackTrace);

        RequestQueue rq = Volley.newRequestQueue(context);
        rq.add(jsonRequest);
    }
}
