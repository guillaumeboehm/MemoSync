package com.example.memosync;

public class ApiCalls {
    static private String domain = "https://yorokobii.ovh/";

    static String getMemoUrl(String userName){
        return domain + "api/?user=" + userName;
    }

    static String getCreateUserUrl(String userName){
        return domain + "api/?user=" + userName + "&new";
    }

    static String getSaveMemoUrl(String userName, String memo){
        return domain + "api/?user=" + userName + "&modif="+memo;
    }
}
