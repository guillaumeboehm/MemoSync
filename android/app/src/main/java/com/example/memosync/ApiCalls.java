package com.example.memosync;

public class ApiCalls {
    static private String domain = "https://yorokobii.ovh/";

    static String getMemoUrl(String userName){
        return domain + "api/?user=" + userName;
    }
}
