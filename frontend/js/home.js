document.title = 'MemoSync - Home';

let memoTemplate = document.getElementById('memo-template');
let memoListDOM = document.querySelector('.list-container ul');
let memoTextArea = document.getElementById('memo-textarea');

async function openMemo(title){
    if(title == null) return 0;
    fetch('https://memosync.net/getMemo', {
        method: 'POST',
        headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer '+localStorage.accessToken
        },
        body:JSON.stringify({
            memoTitle: title
        }, null, 2)
    }).then(res => {
        if(res.status >= 500){ //err
            console.error(res);
        }
        else{
            res.json().then(data=>{
                console.log(data);
                if(data){
                    memoTextArea.value = data.text;
                    memoTextArea.focus();
                    localStorage.setItem('lastOpenedMemo', title);
                    localStorage.setItem('currentMemoVersion', data.version);
                    //TODO list item bg color to show it is selected
                }
            }).catch(res=>console.error(res));
        }
    }).catch(res=>{
        console.error(res);
    });
}

function addMemo(title){
    let newItem = memoTemplate.content.cloneNode(true);
    newItem.querySelector('li').setAttribute('memoTitle', title);
    newItem.querySelector('.memo-title').innerText = title;

    //* Open memo
    newItem.querySelector('li .memo-title').onclick = function() { openMemo(title); }

    //* delete memo
    newItem.querySelector('.delete-memo-button').onclick = function() {
        fetch('https://memosync.net/deleteMemo', {
            method: 'DELETE',
            headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
                'Authorization': 'Bearer '+localStorage.accessToken
            },
            body:JSON.stringify({
                memoTitle: title
            }, null, 2)
        }).then(res => {
            if(res.status >= 500){ //err
                console.error(res);
            }
            else{
                console.log("memo deleted")
                memoListDOM.querySelector('li[memoTitle="'+title+'"]').remove();
                if(localStorage.lastOpenedMemo == title){
                    memoTextArea.value = '';
                    localStorage.setItem('lastOpenedMemo', null);
                }
            }
        }).catch(res=>{
            console.error(res);
        });
    }

    // append to list
    memoListDOM.append(newItem);
}

// new memo
const newMemoBtn = document.getElementById('new-memo-button');
const newMemoInput = document.getElementById('new-memo-input');
newMemoBtn.addEventListener('click', function(){
    newMemoBtn.classList.add("collapse");
    newMemoInput.classList.remove("collapse");
    newMemoInput.focus();
});
newMemoInput.addEventListener('focusout', function(event){
    newMemoInput.classList.add("collapse");
    newMemoBtn.classList.remove("collapse");
    newMemoInput.value = "";
});
newMemoInput.addEventListener("keyup", function(event){
    if(event.keyCode === 13 && newMemoInput.value != ''){
        event.preventDefault();
        console.log('ENTER');

        fetch('https://memosync.net/newMemo', {
            method: 'POST',
            headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
                'Authorization': 'Bearer '+localStorage.accessToken
            },
            body:JSON.stringify({
                memoTitle: newMemoInput.value
            }, null, 2)
        }).then(res => {
            if(res.status >= 300){ //err
                console.error(res);
                if(res.status != 500)
                    res.json().then(data=>{
                        //TODO proper notification
                        if(data.err == 'memoAlreadyExists') console.log('memo already exists');
                    }).catch(res=>console.log(res))
            }
            else{
                console.log("memo created")
                addMemo(newMemoInput.value);
                openMemo(newMemoInput.value);
            }
            newMemoInput.blur();
        }).catch(res=>{
            console.error(res);
        });
    }
});

// save memo
document.getElementById('save-memo-button').addEventListener('click', function(){
        fetch('https://memosync.net/updateMemo', {
            method: 'POST',
            headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
                'Authorization': 'Bearer '+localStorage.accessToken
            },
            body:JSON.stringify({
                memoTitle: localStorage.lastOpenedMemo,
                memoTxt: memoTextArea.value,
                memoVer: Number(1+localStorage.currentMemoVersion)
            }, null, 2)
        }).then(res => {
            if(res.status >= 300){ //err
                console.error(res);
                if(res.status != 500)
                    res.json().then(data=>{
                        //TODO proper notification
                        if(data.version >= localStorage.currentMemoVersion){
                            memoTextArea.value = data.text;
                            localStorage.setItem('currentMemoVersion', data.version);
                        }
                    }).catch(res=>console.log(res))
            }
            else{
                console.log('memo saved');
            }
            newMemoInput.blur();
        }).catch(res=>{
            console.error(res);
        });
});

//******* check authentication
fetch('https://auth.memosync.net/newToken', {
    method: 'POST',
    headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer '+localStorage.accessToken
    },
    body: JSON.stringify({
        'token': localStorage.refreshToken
    }, null, 2)
}).then(res=>{
if(res.status >=300){
    // error on reconnect so purge tokens and reconnect
    localStorage.removeItem('accessToken');
    localStorage.removeItem('refreshToken');
    location.href = '/';
}
console.log(res);
res.json().then(data=>{ localStorage.setItem('accessToken', data.accessToken); });
//******* check authentication

// fetch all the memos
fetch('https://memosync.net/getAllMemos', {
    method: 'GET',
    headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer '+localStorage.accessToken
    }
}).then(res => {
    if(res.status >= 500){ //err
        console.error(res);
    }
    else{
        res.json().then(data=>{
            for(memo of data){
                addMemo(memo.title);
            }
        })
    }
}).catch(res=>{
    console.log(res)
})

//open the last opened memo
if(localStorage.lastOpenedMemo != null) openMemo(localStorage.lastOpenedMemo);

//******* check authentication
}).catch(res=>{
    // error on reconnect so purge tokens and reconnect
    localStorage.removeItem('accessToken');
    localStorage.removeItem('refreshToken');
    location.href = '/';
})
//******* check authentication
