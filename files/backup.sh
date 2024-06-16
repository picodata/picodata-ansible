#!/bin/bash

help_msg () {
      echo ""
      echo "Backup picodata instance"
      echo ""
      echo "$0 [options]"
      echo ""
      echo "options:"
      echo "    -h            show brief help"
      echo "    -s sock-file  name of sock file of instance"
      echo "    -d dir        directory for backup"
      echo ""
      exit 0
}

[ $# -eq 0 ] && help_msg

# collect command line settings
while getopts 's:d:' param ; do
  case $param in
    s)
      SOCK="$OPTARG"
      ;;
    d)
      BACKUP_DIR="$OPTARG"
      ;;
    *)
      help_msg
      ;;
  esac
done

SNAP=$(echo "
\lua
box.snapshot()
box.backup.stop()
box.backup.start()
" | picodata admin $SOCK | grep "snap$" | sed -E 's/.* //g')

[ "$SNAP" = "" ] && exit 2

# /var/lib/picodata/test.storage-1001/00000000000000002055.snap > test.storage-1001
SNAP_DIR=$(dirname $SNAP | xargs basename)

SNAPOWNER=$(stat -c %U:%G $SNAP)
mkdir -p $BACKUP_DIR/$SNAP_DIR
chown $SNAPOWNER $BACKUP_DIR/$SNAP_DIR

cp -p $SNAP $BACKUP_DIR/$SNAP_DIR/

echo "
\lua
box.backup.stop()
" | picodata admin $SOCK &>/dev/null