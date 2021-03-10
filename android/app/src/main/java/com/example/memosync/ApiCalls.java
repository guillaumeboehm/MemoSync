package com.example.memosync;

import java.util.HashMap;

public class ApiCalls {
    static private String domain = "https://yorokobii.ovh/";

    // GET STUFF OUTDATED SUCKS BOOBOO
    static String getMemoUrl(String userName){
        return domain + "api/?user=" + userName;
    }

    static String getCreateUserUrl(String userName){
        return domain + "api/?user=" + userName + "&new";
    }

    static String getSaveMemoUrl(String userName, String memo){
        return domain + "api/?user=" + userName + "&modif="+memo;
    }

    // POST STUFF PRETTY GUD NOICE FEELS GUD
    static String postMemoUrl(){
        return domain + "post_api/get_memo.php";
    }
    static HashMap<String,String> postMemoParams(String userName){ return new HashMap<String,String>(){{put("user", userName);}}; }

    static String postCreateUserUrl(){
        return domain + "post_api/new_memo.php";
    }
    static HashMap<String,String> postCreateUserParams(String userName){ return new HashMap<String,String>(){{put("user", userName);}}; }

    static String postSaveMemoUrl(){
        return domain + "post_api/set_memo.php";
    }
    static HashMap<String,String> postSaveMemoParams(String userName, String memo,Integer version){
        return new HashMap<String,String>(){{put("user", userName);
                                             put("memo", memo);
                                             put("version",version.toString());}};
    }
}
