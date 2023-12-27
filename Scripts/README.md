# README - Scripts directory

The intent of this directory ~/Scripts is files that can be run non-interactively, broken down by "area of concern".
Non-interactive files will go in ~/Foo


Eventually, I would like to be able to simply run the following to build my environment
```
for SCRIPT in $(ls [0-9]*.sh | sort); do sh ./$SCRIPT; done
```


