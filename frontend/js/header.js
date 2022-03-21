// check auth
if(localStorage.getItem('refreshToken') !== null){
    for(let el of document.querySelectorAll('.loggedin')) el.classList.remove('display-none');
    for(let el of document.querySelectorAll('.loggedout')) el.classList.add('display-none');
} else {
    for(let el of document.querySelectorAll('.loggedout')) el.classList.remove('display-none');
    for(let el of document.querySelectorAll('.loggedin')) el.classList.add('display-none');
}

document.getElementById('header-logout').onclick = ()=>{
    fetch('https://auth.memosync.net/logout', {
        method: 'DELETE',
        headers : {
            'Accept': 'application/json',
            'Content-Type': 'application/json'
        },
        body:JSON.stringify({
            refreshToken: localStorage.getItem('refreshToken')
        }, null, 2)
    }).then(res => {
        if(res.status >= 300){ //err
            res.json().then(data=>{
                if(data.err == 'NoUserFound'){//logout anyway
                    localStorage.removeItem('accessToken');
                    localStorage.removeItem('refreshToken');
                    location.href = '/';
                }
                console.error(data.err);
            });
        }
        else{
            localStorage.removeItem('accessToken');
            localStorage.removeItem('refreshToken');
            location.href = '/';
        }
    });
}
document.getElementById('header-signup').onclick = ()=>{
    location.href = '/signup';
}
