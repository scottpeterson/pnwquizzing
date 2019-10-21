# PNW Bible Quizzing

Web site, documents, statistics, and tools in support of the **PNW Bible
Quizzing** program.

## Setup

To setup this application in a new environment, you will need to ensure the
following prerequisites are installed:

- Perl
- CPANminus (`cpanm`)
- SQLite
- `libsass`

Then perform the following from within the project's root folder:

    cpanm -n -f --installdeps .

## Run

To run the application for a development enviornment with auto-restart on code
changes, you can perform the following:

    morbo -v -w docs -w config -w lib -w templates app.psgi

To run the application for a production enviornment, you can perform the
following:

    hypnotoad app.psgi

## Photo Optimization

Within `~/static/photos` reside many JPG photo image files. These are
automatically picked up and displayed at random across most rendered pages.
Use the following procedure to optimize photos prior to add/commit:

    for file in $( ls *.{jpg,png,gif} 2> /dev/null )
    do
        name=$(echo $file | sed 's/\.[^\.]*$//')
        convert $file -resize 440\> $name.jpg
    done
    rm *.{png,gif}
    jpegoptim -s *.jpg

Requires:

- `imagemagick`
- `jpegoptim`
