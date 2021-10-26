document.title = 'MemoSync - Email verification';
fetch('https://auth.memosync.net/verifEmail'+window.location.search, {
    method: 'GET',
    headers : {
        'Accept': 'application/json'
    }
}).then(res => {
    if(res.status >= 500){ //err
        console.error(res);
    }
    else{
        res.json().then(data=>{
            document.getElementById('text').innerText = data.text;
            document.getElementById('button').innerText = data.button;
            document.getElementById('button').href = data.redirect;
        })
    }
}).catch(res=>{
    console.error(res);
});
