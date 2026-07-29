# Task 10.2.3 dart:io Import Hotfix

The fake filesystem throws `FileSystemException`, which is declared in
`dart:io`. The original GREEN file omitted that import.

This patch only adds the missing import.
