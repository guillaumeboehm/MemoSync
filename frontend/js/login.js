document.title = 'MemoSync - Login';
let message = document.getElementById('message');
document.querySelector('form').onsubmit = (e)=>{
    message.classList.remove('show');
    document.querySelector('.button-text').classList.remove('show');
    document.querySelector('.button-load').classList.add('show');

    fetch('https://auth.memosync.net/login', {
        method: 'POST',
        headers : {
            'Accept': 'application/json',
            'Content-Type': 'application/json'
        },
        body:JSON.stringify({
            email: document.getElementById('login-email').value,
            password: document.getElementById('login-password').value
        }, null, 2)
    }).then(res => {
        document.querySelector('.button-text').classList.add('show');
        document.querySelector('.button-load').classList.remove('show');
        if(res.status >= 300){ //err
            res.json().then(data=>{
                console.error(data.err);
                switch(data.err){
                    case 'NoUserFound':
                        message.innerText = 'No user was found with this email.';
                        break;
                    case 'WrongPass':
                        message.innerText = 'Wrong password.';
                        break;
                    case 'VerifEmail':
                        message.innerText = 'Verify your email before logging in. Don\'t forget to check your spam folders.';
                        break;
                    default:
                        message.innerText = 'Unkown error please try again.';
                }
                message.classList.add('show');
            });
        }
        else{
            res.json().then(data=>{
                localStorage.setItem('refreshToken', data.refreshToken);
                localStorage.setItem('accessToken', data.accessToken);
                location.href = '/';
            })
        }
    }).catch(res=>{
        document.querySelector('.button-text').classList.add('show');
        document.querySelector('.button-load').classList.remove('show');
        message.innerText = res
    });
    return false;
}
let reveal_pwd_button = document.getElementById('reveal-password');
let pwd_input = document.getElementById('login-password');
reveal_pwd_button.onclick = ()=>{
    pwd_input.setAttribute('type', pwd_input.getAttribute('type')=='text'?'password':'text');
}
