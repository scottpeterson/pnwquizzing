( function () {
    var nav;
    var content;
    var header;

    function nav_content_align() {
        if ( nav.offsetHeight < content.offsetHeight ) {
            var height = content.scrollHeight - header.scrollHeight;

            nav.style.maxHeight = height + "px";
            nav.style.height    = height + "px";
        }
    }

    window.addEventListener( 'load', function() {
        nav     = document.getElementById("nav");
        content = document.getElementById("content");
        header  = document.getElementById("header");

        nav_content_align();
    } );

    window.addEventListener( 'resize', function() {
        nav_content_align();
    } );
}() );
