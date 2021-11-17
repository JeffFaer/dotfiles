if did_filetype()
  finish
endif
if getline(1) =~ '^#!/usr/bin/env -S bash'
  setfiletype sh
endif
