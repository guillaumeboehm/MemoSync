chrome.runtime.connect({ name: "popup" });

var bck_page;
chrome.runtime.getBackgroundPage(function(page){bck_page = page;})
var loading=false;

function getUser(){
  return localStorage.getItem('memosync_user')
}
function setUser(_user){
  return localStorage.setItem('memosync_user', _user)
}
function doesUserExists(_user, callback){ 
  // fetch the memo html page
  var data = new FormData();
  data.append('user', _user);

  var xhr = new XMLHttpRequest();
  // xhr.open('GET', 'https://yorokobii.ovh/api/', true);
  xhr.open('GET', 'https://yorokobii.ovh/api/?user='+_user, true);
  xhr.onload = function(){
    // parse the memo in the html page
    memo = this.response;
    let regex = /unknown_user/gm
    let matches = memo.match(regex)

    callback(matches === null);
  };
  xhr.send(data);
}

function swap_divs(){
  if(getUser() !== null){ // user is saved in local storage
    document.getElementById("login_div").style.display = 'none';
    document.getElementById("memo_div").style.display = 'block';
    fetch_memo();
  }
  else{
    document.getElementById("memo_div").style.display = 'none';
    document.getElementById("login_div").style.display = 'block';
  }
}
function fetch_memo(){
  if(getUser() !== null){
    var memo;

    // fetch the memo html page
    var data = new FormData();
    data.append('user', getUser());

    var xhr = new XMLHttpRequest();
    // xhr.open('GET', 'https://yorokobii.ovh/api/', true);
    xhr.open('GET', 'https://yorokobii.ovh/api/?user='+getUser(), true);
    xhr.onload = function(){
      // parse the memo in the html page
      console.debug("fetch_memo request response",this.response);
      memo = this.response;

      let regex = /(<.*>)/gm // removes all html elements
      memo = memo.replaceAll(regex, '');
      regex = /(^\s*$)/gm // cleans the whitespaces
      memo = memo.replaceAll(regex, '');
      regex = /(^\s|\s$)/g // cleans the first and last linebreaks
      memo = memo.replace(regex, '');

      setText(memo);
    };
    xhr.send(data);
  }
  else
    setText("");
}
function register_user(){
  if(getUser() !== null){
    var data = new FormData();
    data.append('user', getUser());

    var xhr = new XMLHttpRequest();
    // xhr.open('GET', 'https://yorokobii.ovh/api/', true);
    xhr.open('GET', 'https://yorokobii.ovh/api/?user='+getUser()+'&new', true);
    xhr.onload = function(){
      //? error handling
      setText("");
    };
    xhr.send(data);
  }
}

function getText(){
  return document.getElementById("memo").innerHTML;
}
function setText(_text){
  document.getElementById("memo").innerHTML = _text;
  setMemo(_text);
}
function getMemo(){
  return bck_page.memo;
}
function setMemo(_text){
  bck_page.memo = _text;
}

function saveMemo(){
  bck_page.saveMemo();
}


document.getElementById("user_name").addEventListener("keyup", function(event) {
  // Number 13 is the "Enter" key on the keyboard
  if (event.keyCode === 13) {
    event.preventDefault();
    document.getElementById("login_button").click();
  }
});


async function try_login(_user){
  load();
  document.getElementById("login_warning_message").style.display = 'none';
  doesUserExists(_user, (exists)=>{
    if(exists){
      setUser(_user)
      swap_divs(getUser())
      fetch_memo();
    }
    else{
      document.getElementById("login_warning_message").style.display = 'block';
      document.getElementById("login_warning_message").innerHTML = 'This user does not exist, click register to create this user.';
    }
    stop_load();
  })
}
document.getElementById("login_button").addEventListener('click', function(){
  let input_user = document.getElementById("user_name").value;
  if(input_user !== ''){
    try_login(input_user);
  }
})

async function try_register(_user){
  load();
  document.getElementById("login_warning_message").style.display = 'none';
  doesUserExists(_user, (exists)=>{
    if(exists){
      document.getElementById("login_warning_message").style.display = 'block';
      document.getElementById("login_warning_message").innerHTML = 'This user already exists, click login to connect.';
    }
    else{
      setUser(_user)
      swap_divs(getUser())
      register_user();
    }
    stop_load();
  })
}
document.getElementById("register_button").addEventListener('click', function(){
  let input_user = document.getElementById("user_name").value;
  if(input_user !== ''){
    try_register(input_user);
  }
})


document.getElementById("logout_button").addEventListener('click', function(){
  saveMemo();
  localStorage.removeItem('memosync_user')
  swap_divs(getUser())
})
document.getElementById("options_button").addEventListener('click', function(){
  saveMemo();
  // open options
})
document.getElementById("save_button").addEventListener('click', function(){
  saveMemo();
})
document.getElementById("memo").addEventListener('change', function(event){
  console.debug(event.target.value);
  setMemo(event.target.value);
})

async function load(){
  loading = true;
  let loading_span = document.getElementById("loading_span");
  let count = 0;
  let step = 500; //ms
  loading_span.style.display = "block";
  loading_span.innerHTML = "Loading.";

  function incr_load() {
    return new Promise(resolve => {
      setTimeout(() => {
        loading_span.innerHTML = "Loading";
        count = (++count)%4;
        for (let i = 0; i < count; i++) {
          loading_span.innerHTML += '.';
        }
        resolve();
      }, step);
    });
  }

  while(loading){
    await incr_load();
  }
}
function stop_load(){
  loading = false;
  document.getElementById("loading_span").style.display = 'none';
}


swap_divs(getUser())