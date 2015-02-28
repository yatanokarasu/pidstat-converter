
What is this?
=============

This script converts logs that are obtained by `pidstat` command to CSV format file.


What does we need to prepare?
=============================

1.  This script needs perl command.

2.  perform `pidsat` command with `-hur` options and redirect text file has `.pidstat` ext. as below:
    ``` shell
    $ pidstat -hur >test.pidstat
    ```


How to use this?
================

You can use the followin usage:

1.  `> pidstat-converter.bat ${PIDSTAT_LOG_FILE}`

2.  `> perl pidstat-converter.bat ${PIDSTAT_LOG_FILE}`
