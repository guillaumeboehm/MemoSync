document.title = 'MemoSync - Resend verification email';
let message = document.getElementById('message');
document.querySelector('form').onsubmit = (e)=>{
    message.classList.remove('show');
    message.classList.remove('success');
    document.querySelector('.button-text').classList.remove('show');
    document.querySelector('.button-load').classList.add('show');

    fetch('https://auth.memosync.net/resendVerif', {
        method: 'POST',
        headers : {
            'Accept': 'application/json',
            'Content-Type': 'application/json'
        },
        body:JSON.stringify({
            email: document.getElementById('email').value
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
                    case 'AlreadyVerified':
                        message.classList.add('success');
                        message.innerText = 'Your email has already been verified. Try logging in.';
                        break;
                    case 'UnqualifiedAddress':
                        message.innerText = 'The given address is not fully-qualified.';
                        break;
                    default:
                        message.innerText = 'Unkown error please try again.';
                }
                message.classList.add('show');
            });
        }
        else{
            message.classList.add('success');
            message.innerText = 'A new verification link has been sent to your email. Don\'t forget to check your spam folders';
        }
    }).catch(res=>{
        message.innerText = res
    });
    return false;
}
