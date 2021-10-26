document.title = 'MemoSync - Sign up';
let message = document.getElementById('message');
document.querySelector('form').onsubmit = (e)=>{
    message.classList.remove('show');
    const password = document.getElementById('signup-password').value;
    const passwordConfirm = document.getElementById('signup-password-confirm').value;

    if(password !== passwordConfirm){
        message.innerText = "The passwords don't match";
        message.classList.add('show');
        return false;
    }
    document.querySelector('.button-text').classList.remove('show');
    document.querySelector('.button-load').classList.add('show');

    fetch('https://auth.memosync.net/signup', {
        method: 'POST',
        headers : {
            'Accept': 'application/json',
            'Content-Type': 'application/json'
        },
        body:JSON.stringify({
            email: document.getElementById('signup-email').value,
            password: password
        }, null, 2)
    }).then(res => {
        document.querySelector('.button-text').classList.add('show');
        document.querySelector('.button-load').classList.remove('show');
        if(res.status >= 300){ //err
            res.json().then(data=>{
                console.error(data.err);
                switch(data.err){
                    case 'UnqualifiedAddress':
                        message.innerText = 'The email address is not fully-qualified.';
                        break;
                    case 'UserAlreadyExists':
                        message.innerText = 'This email is already in use, try logging in.';
                        break;
                    default:
                        message.innerText = 'Unkown error please try again.';
                }
                message.classList.add('show');
            });
        }
        else{
            location.href = '/login';
        }
    }).catch(err => {
        console.log(err);
        document.querySelector('.button-text').classList.add('show');
        document.querySelector('.button-load').classList.remove('show');
    });
    return false;
}
let reveal_pwd_button = document.getElementById('reveal-password');
let pwd_input = document.getElementById('signup-password');
reveal_pwd_button.onclick = ()=>{
    pwd_input.setAttribute('type', pwd_input.getAttribute('type')=='text'?'password':'text');
}
document.getElementById('signup-password-confirm').addEventListener('paste', (e) => {
  e.preventDefault(); // This is what prevents pasting.
});
