document.title = 'MemoSync - Change password';
let message = document.getElementById('message');
document.querySelector('form').onsubmit = (e)=>{
    message.classList.remove('show');
    message.classList.remove('success');
    document.querySelector('.button-text').classList.remove('show');
    document.querySelector('.button-load').classList.add('show');

    const accessToken = localStorage.getItem('accessToken');
    let urlParams = new URLSearchParams(window.location.search);
    const user = urlParams.get("user");
    const resetToken = urlParams.get("token");

    const password = document.getElementById('password').value;
    const passwordConfirm = document.getElementById('password-confirm').value;
    if(password !== passwordConfirm){
        message.innerText = "The passwords don't match";
        message.classList.add('show');
        document.querySelector('.button-text').classList.add('show');
        document.querySelector('.button-load').classList.remove('show');
        return false;
    }

    fetch('https://auth.memosync.net/changePassword', {
        method: 'POST',
        headers : {
            'Accept': 'application/json',
            'Content-Type': 'application/json'
        },
        body:JSON.stringify({
            accessToken: accessToken || undefined,
            user: user || undefined,
            resetToken: resetToken || undefined,
            password: password
        }, null, 2)
    }).then(res => {
        document.querySelector('.button-text').classList.add('show');
        document.querySelector('.button-load').classList.remove('show');
        if(res.status >= 300){ //err
            if(res.status >= 500){
                console.error(res);
                return false;
            }
            res.json().then(data=>{
                console.error(data.err);
                switch(data.err){
                    case 'NoUserFound':
                        message.innerText = 'No user was found with this email, try signing up.';
                        break;
                    case 'MalformedLink':
                        message.innerText = 'The reset link is malformed try resending the reset link again.';
                        break;
                    default:
                        message.innerText = 'Unkown error please try again.';
                }
                message.classList.add('show');
            });
        }
        else{
            message.classList.add('success');
            message.innerText = 'Your password has been changed.';
        }
    }).catch(res=>{
        message.innerText = res
    });
    return false;
}
let reveal_pwd_button = document.getElementById('reveal-password');
let pwd_input = document.getElementById('password');
reveal_pwd_button.onclick = ()=>{
    pwd_input.setAttribute('type', pwd_input.getAttribute('type')=='text'?'password':'text');
}
document.getElementById('password-confirm').addEventListener('paste', (e) => {
  e.preventDefault(); // This is what prevents pasting.
});
