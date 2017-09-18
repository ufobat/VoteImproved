function change_image_rating(value, imageid) {
    var xhr  = new XMLHttpRequest();
    var data = new FormData();
    data.append('image', imageid );
    data.append('rating', value);
    xhr.open('POST','/vote/vote_image/' + imageid, true);
    console.log('rating: ' + value);
    // xhr.setRequestHeader('Content-Type', data.contentType);
    xhr.onreadystatechange = function() {//Call a function when the state changes.
        if(xhr.readyState == 4) {
            console.log(xhr.status);
            console.log(xhr.responseText);
        }
    }
    xhr.send(data);
    console.log(value);
}
