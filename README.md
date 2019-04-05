# PNW Bible Quizzing

Web site, documents, statistics, and tools in support of the **PNW Bible
Quizzing** program.

## Setup

To setup this application in a new enviornment, perform the following from
within the project's root folder:

    cpanm -n -f --with-develop --with-all-features --installdeps .
    mkdir local
    dest init
    dest update

## Run

To run the application for a development enviornment with auto-restart on code
changes, you can perform the following:

    morbo -w config -w lib -w templates config/app.pl

To run the application for a production enviornment, you can perform the
following:

    hypnotoad app.pl
