package com.example.memosync;

import android.annotation.SuppressLint;
import android.content.Context;
import android.os.AsyncTask;
import android.os.Build;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.UnsupportedEncodingException;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.Iterator;

/**
 * HttpRequestTask is an abstract extension of an AsyncTask for HTTP Requests.
 *
 * @param <P>
 *      Type for parameter(s) to doInBackground (can be Void if none provided)
 * @param <R>
 *      Type for result of request (can be Void if ignored, or using listeners.)
 */
public abstract class HttpRequestTask<P, R> extends AsyncTask<P, Integer, R>
{
    private static final String TAG = "HttpRequestTask";

    // Post form encoded requests, get back JSON response
    private static final RequestMethod DEFAULT_REQUEST_METHOD = RequestMethod.POST;
    private static final String DEFAULT_CONTENT_TYPE = "application/x-www-form-urlencoded;charset=UTF-8;";
    private static final String DEFAULT_ACCEPT = "application/json;";
    private static final int DEFAULT_TIMEOUT = 8000; // 8 seconds
    private static final String CHARSET = "UTF-8";

    protected static final String NULL_CONTEXT = "Context is null.";
    protected static final String INVALID_RESPONSE = "The server did not send back a valid response.";
    @SuppressLint("StaticFieldLeak")
    private Context context;

    // Request methods supported by back-end
    protected enum RequestMethod
    {
        GET("GET"),
        POST("POST");

        private final String method;

        RequestMethod(String method)
        {
            this.method = method;
        }

        @Override
        public String toString()
        {
            return this.method;
        }
    }

    /**
     * ALWAYS use application context here to prevent memory leaks.
     *
     */
    protected HttpRequestTask(@NonNull final Context context)
    {
        this.context = context;
    }
/*
    protected void verifyConnection() throws IOException
    {
        if (!SystemUtil.isInternetAvailable(context))
        {
            throw new IOException("Internet is unavailable.");
        }
    }
*/
    /**
     * Creates and opens a URLConnection for the url parameter, as well as setting request options.
     *
     * @param url
     *      to connect to.
     *
     * @return opened HTTPURLConnection for POSTing data to ctservices.
     */
    protected HttpURLConnection getURLConnection(URL url) throws IOException
    {
        return this.getURLConnection(url, DEFAULT_REQUEST_METHOD, DEFAULT_CONTENT_TYPE,
                DEFAULT_ACCEPT, DEFAULT_TIMEOUT);
    }

    /**
     * Creates and opens a URLConnection for the url parameter, as well as setting request options.
     *
     * @param url
     *      to connect to.
     *
     * @return opened HTTPURLConnection
     */
    protected HttpURLConnection getURLConnection(@NonNull final URL url,
                                                 @NonNull final RequestMethod requestMethod,
                                                 @NonNull final String contentType,
                                                 @Nullable final String accept, final int timeout)
            throws IOException
    {
        //verifyConnection();

        HttpURLConnection urlConnection = (HttpURLConnection) url.openConnection();
        urlConnection.setRequestMethod(requestMethod.toString());
        urlConnection.setRequestProperty("Content-Type", contentType);

        if (accept != null && !accept.isEmpty())
        {
            urlConnection.setRequestProperty("Accept", accept);
        }

        urlConnection.setReadTimeout(timeout);
        urlConnection.setConnectTimeout(timeout);
        urlConnection.setUseCaches(false);
        urlConnection.setDoInput(true);
        urlConnection.setDoOutput(true);
        return urlConnection;
    }

    /**
     * Creates and opens a URLConnection for the url parameter, but does not set any request options.
     *
     * @param url
     *      to connect to.
     *
     * @return opened HTTPURLConnection without parameters set.
     */
    protected HttpURLConnection getBasicURLConnection(URL url) throws IOException
    {
        /*
        if (!SystemUtil.isInternetAvailable(applicationContext.get()))
        {
            throw new IOException("Internet is unavailable.");
        }*/

        HttpURLConnection urlConnection = (HttpURLConnection) url.openConnection();
        return urlConnection;
    }

    /**
     * Write a JSONObject of request parameters to the output stream as form-encoded data.
     *
     * @param urlConnection
     *      opened urlConnection with output enabled (done by getURLConnection).
     * @param params
     *      to write to request.
     *
     * @throws IOException
     *      problem writing to output stream
     */
    @RequiresApi(api = Build.VERSION_CODES.KITKAT)
    protected void writeParams(HttpURLConnection urlConnection, JSONObject params) throws IOException
    {
        OutputStream outputStream = urlConnection.getOutputStream();
        BufferedWriter outWriter = new BufferedWriter(new OutputStreamWriter(outputStream,
                StandardCharsets.UTF_8));

        String urlParams = this.encodeJSONObject(params);

        outWriter.write(urlParams);
        outWriter.flush();
        outWriter.close();
        outputStream.close();
    }

    /**
     * Reads the response of a URLConnection from the input stream and puts it in a string.
     *
     * @param urlConnection
     *      opened urlConnection with input enabled (done by getURLConnection).
     *
     * @return response string
     *
     * @throws IOException
     *      problem reading input stream
     */
    protected String readResponse(HttpURLConnection urlConnection) throws IOException
    {
        InputStream inputStream = null;

        try
        {
            /* If we failed to connect will throw a SocketResponseTimeoutException,
             * which is an IOException. */
            int responseCode = urlConnection.getResponseCode();

            if (HttpURLConnection.HTTP_OK != responseCode)
            {
                throw new IOException("Bad response code - " + responseCode);
            }

            inputStream = urlConnection.getInputStream();
            final String response = parseInputStream(inputStream);
            urlConnection.disconnect();
            return response;
        }
        finally
        {
            if (inputStream != null)
            {
                try
                {
                    inputStream.close();
                }
                catch (Exception e) {}
            }
        }
    }

    protected Context getContext()
    {
        return this.context;
    }

    protected String getString(final int resId)
    {
        return getContext().getString(resId);
    }

    /**
     * Encodes a JSONObject as a form-data URL string.
     *
     * @param jo
     *      to encode
     *
     * @return encoded URL string
     */
    private String encodeJSONObject(JSONObject jo)
    {
        StringBuilder sb = new StringBuilder();
        boolean first = true;
        Iterator<String> itr = jo.keys();
        String key;
        Object val;

        try
        {
            while (itr.hasNext())
            {
                key = itr.next();
                val = jo.get(key);

                if (first)
                {
                    first = false;
                }
                else
                {
                    sb.append('&');
                }

                sb.append(URLEncoder.encode(key, CHARSET));
                sb.append('=');
                sb.append(URLEncoder.encode(val.toString(), CHARSET));
            }
        }
        catch (JSONException | UnsupportedEncodingException e) {}

        return sb.toString();
    }

    private String parseInputStream(InputStream is) throws IOException
    {
        BufferedReader br = null;

        try
        {
            br = new BufferedReader(new InputStreamReader(is));
            StringBuilder sb = new StringBuilder();
            String line;

            while ((line = br.readLine()) != null)
            {
                sb.append(line);
            }

            return sb.toString();
        }
        finally
        {
            if (br != null)
            {
                try
                {
                    br.close();
                }
                catch (Exception e) {}
            }
        }
    }

    /**
     * Merges any properties of b into a that don't already have a key match in a.
     *
     * @param a
     *      merging to
     * @param b
     *      merging from
     *
     * @return a with any unique values from b
     */
    protected JSONObject mergeJSONObjects(JSONObject a, JSONObject b)
    {
        if (b == null)
        {
            return a;
        }
        if (a == null)
        {
            return b;
        }

        try
        {
            Iterator<String> bItr = b.keys();
            String key;
            while (bItr.hasNext())
            {
                key = bItr.next();
                if (!a.has(key))
                {
                    a.put(key, b.get(key));
                }
            }

            return a;
        }
        catch (Exception ex)
        {
            Log.e(TAG, ex.getClass().getSimpleName() + " in mergeJSONObjects: " + ex.getMessage() +
                    '\n' + Log.getStackTraceString(ex));
            return a;
        }
    }
}