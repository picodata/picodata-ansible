#!/bin/bash

help_msg () {
      echo ""
      echo "Restore picodata instance"
      echo ""
      echo "$0 [options]"
      echo ""
      echo "options:"
      echo "    -h            show brief help"
      echo "    -n name       name of cluster"
      echo "    -d dir        directory for data files"
      echo "    -b dir        directory for backup"
      echo ""
      exit 0
}

[ $# -eq 0 ] && help_msg

# collect command line settings
while getopts 'n:b:d:' param ; do
  case $param in
    n)
      CLUSTER="$OPTARG"
      ;;
    d)
      DATA_DIR="$OPTARG"
      ;;
    b)
      BACKUP_DIR="$OPTARG"
      ;;
    *)
      help_msg
      ;;
  esac
done

echo "Stop all instances of cluster $CLUSTER on hosts"
systemctl stop $CLUSTER@*

echo "Remove current data"
rm -rf $DATA_DIR/$CLUSTER/*

echo "Make dest dir"
mkdir -p $DATA_DIR/$CLUSTER/

echo "Restore data from backup"
cp -pr $BACKUP_DIR/* $DATA_DIR/$CLUSTER/

echo "Start all instances of cluster $CLUSTER on hosts"
systemctl start --all $CLUSTER@*
