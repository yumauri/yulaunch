# Parameters #

You can use following command line parameters (in Opera there is special field for them, you can use it).

> -d | --debug → turns on debug mode, and will output debug messages (on Windows with message box, on Linux – to stdout)

> -s → defines delimeter, same as "spacer" property in configuration file

> --register → **windows only** try to register protocol handlers in Windows registry, it will make possibility to use tool with Internet Explorer (but I didn't test it…)

> --unregister ­→ **windows only** try to remove protocol handlers from registry

# Compilation #

To compile program you will need [Free Pascal](http://www.freepascal.org/) compiler. It is pretty simple, just type
```
fpc yulaunch.pp
```