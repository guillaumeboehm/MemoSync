package com.example.memosync;

import android.content.Context;
import android.util.Pair;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;

public class ConfigFile {
    static private JSONObject json = null;
    static private String filename = "config";
    static private Pair<String,String>[] format = new Pair[] {
            new Pair("user", ""),
            new Pair("test", "AAAAAAAAH")
    };

    static JSONObject getJson(Context context){
        if(json == null) // try to load it
            if(!load(context)) return null;
        return json;
    }

    static boolean set(String key, String value,Context... context){
        try {
            json.put(key,value);
            if(context.length > 0)//try saving
                return saveFile(context[0]); // return saveFile success/fail
            return true; // success
        } catch (JSONException e) {e.printStackTrace();}
        return false; // fail
    }

    static boolean load(Context context){
        try {
            FileInputStream fin = context.openFileInput("config");
            int c;
            String temp="";
            while( (c = fin.read()) != -1){
                temp = temp + (char) c;
            }
            json = new JSONObject(temp);
            return true; //success
        } catch (FileNotFoundException e) {e.printStackTrace();}
          catch (IOException e) {e.printStackTrace();}
          catch (JSONException e) {e.printStackTrace();}
        return create(context); // return create success/fail
    }

    static boolean create(Context context){
        json = new JSONObject();
        try {
            for(Pair<String,String> element : format)
                json.put(element.first,element.second);
                return saveFile(context);// return save file success/fail
        } catch (JSONException e) {e.printStackTrace();}
        json = null; // if failed
        return false; //fail
    }

    static boolean saveFile(Context context){
        try (FileOutputStream fos = context.openFileOutput(filename, Context.MODE_PRIVATE)) {
            fos.write(json.toString().getBytes());
            return true; // success
        } catch (FileNotFoundException e) {e.printStackTrace();}
          catch (IOException e) {e.printStackTrace();}
        return false; //fail
    }

    static boolean deleteFile(Context context){
        File file = new File(context.getFilesDir(), filename);
        return file.delete();
    }
}
