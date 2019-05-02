( function () {
    window.addEventListener( 'load', function() {
        search_icon = document.getElementById("search_icon");
        search_form = document.getElementById("search_form");

        search_icon.onclick = function () {
            var search_text = prompt("What would you like to search for?");
            if (search_text) {
                search_form.for.value = search_text;
                search_form.submit();
            }
        }
    } );
}() );
