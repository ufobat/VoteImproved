function change_image_rating(value, imageid) {
    var xhr  = new XMLHttpRequest();
    var data = new FormData();
    data.append('image', imageid );
    data.append('rateing', value);
    xhr.open('POST', '/vote/vote-image/' + imageid, true);

    xhr.setRequestHeader("Content-type", "application/x-www-form-urlencoded");

    xhr.onreadystatechange = function() {//Call a function when the state changes.
        if(xhr.readyState == 4) {
            console.log(xhr.status);
            console.log(xhr.responseText);
        }
    }
    xhr.send(data);
    console.log(value);
}
