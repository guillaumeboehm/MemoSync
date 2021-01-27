(function () {
    var invocation = new XMLHttpRequest();
    var url = 'https://cors-anywhere.herokuapp.com/http://91.171.185.227:50001/';

    document.body.innerHTML = "EY";

    // if (invocation) {
    //     invocation.open('GET', url, true);
    //     invocation.onreadystatechange = function () {
    //         if (invocation.readyState === 4 && invocation.status === 200) {
    //             // console.log(invocation.responseText);
    //             document.body.innerText = invocation.responseText;
    //         }
    //     };
    //     invocation.send();
    // }
})();