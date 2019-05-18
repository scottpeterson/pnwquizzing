var nav_content_align = ( function () {
    var nav;
    var content;
    var header;

    return {
        setup: function () {
            nav     = document.getElementById("nav");
            content = document.getElementById("content");
            header  = document.getElementById("header");
        },

        align: function () {
            if ( nav.offsetHeight < content.offsetHeight ) {
                var height = content.scrollHeight - header.scrollHeight;

                nav.style.maxHeight = height + "px";
                nav.style.height    = height + "px";
            }
        }
    };
} )();

window.addEventListener( 'load', function() {
    nav_content_align.setup();
    nav_content_align.align();
} );

window.addEventListener( 'resize', function() {
    nav_content_align.align();
} );
