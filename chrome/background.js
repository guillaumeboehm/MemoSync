chrome.runtime.onInstalled.addListener(function() {
  chrome.storage.sync.remove('memosync_user'); //makes sure no user is set
  console.debug(chrome.extension.getViews())
});

var memo;

function saveMemo() {
  let _user = localStorage.getItem("memosync_user");
  if(_user !== null){
    // fetch the memo html page
    var data = new FormData();
    data.append('user', _user);
    data.append('modif', memo);

    var xhr = new XMLHttpRequest();
    // xhr.open('GET', 'https://yorokobii.ovh/api/', true);
    xhr.open('GET', 'https://yorokobii.ovh/api/?user='+_user+'&modif='+memo, true);
    xhr.onload = function(){
      //? error handling
    };
    xhr.send(data);
  }
}

chrome.runtime.onConnect.addListener(function(port) {
  if (port.name === "popup") {
    port.onDisconnect.addListener(function() {
      saveMemo();
    });
  }
});

