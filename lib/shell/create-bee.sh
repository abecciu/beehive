#!/bin/sh

BASE_DIR=[[WORKING_DIRECTORY]]
GIT_REPOS=[[LOCAL_GIT_REPOS]]

cd [[WORKING_DIRECTORY]]

APP_NAME=[[APP_NAME]]
OUTFILE=[[OUTFILE]]

APP_DIR=[[WORKING_DIRECTORY]]/$APP_NAME	
GIT_REPOS_DIR=$APP_DIR/home/app

echo "app_dir $APP_DIR"
rm -rf $APP_DIR

mkdir -p $APP_DIR
mkdir -p $APP_DIR/home
mkdir -p $APP_DIR/etc
mkdir -p $APP_DIR/bin
mkdir -p $APP_DIR/lib
mkdir -p $APP_DIR/usr
mkdir -p $APP_DIR/usr/bin
mkdir -p $APP_DIR/dev
mkdir -p $APP_DIR/tmp
mkdir -p $APP_DIR/proc

cd $APP_DIR

if [ -d /lib64 ]; then
  mkdir -p lib64/ >/dev/null 2>&1
fi
if [ ! -e dev/null ]; then
  mknod dev/null c 1 3 >/dev/null 2>&1
fi
if [ ! -e dev/zero ]; then
  mknod dev/zero c 1 5 >/dev/null 2>&1
fi

# Yes, this is redundant, but... will do for now
git clone --depth 0 [[GIT_REPOS]] $GIT_REPOS_DIR >/dev/null 2>&1
cd $GIT_REPOS_DIR
SHA=$(git log --max-count=1 | awk '/commit/ {print $2}')
echo "sha $SHA"
cd ../

# Clean the git repos of the pesky .git directory... 'cause who needs it anyway
rm -rf $GIT_REPOS_DIR/.git

# Install from files
GEM_FILE=$GIT_REPOS_DIR/.gems
if [ -f $GEM_FILE ]; then
  for line in $(cat $1/.gems); do
    gem install $line --no-ri --no-rdoc; 
  done
fi

# Make sure this directory doesn't exist
rm $OUTFILE

# Make the squashfs filesystem
mksquashfs $APP_DIR $OUTFILE >/dev/null 2>&1

if [ $? != 0 ]; then
	exit 1
fi
# mksquashfs $TMP_GIT_CLONE $FS_DIRECTORY/$TIMESTAMPED_NAME >/dev/null 2>&1
# # Link it as the "latest" filesystem
# ln -sf $FS_DIRECTORY/$TIMESTAMPED_NAME $MOUNT_FILE

dir_size=`du -h -s $APP_DIR | awk '{print $1}'`
bee_size=`du -h -s $OUTFILE | awk '{print $1}'`
echo "bee_size $bee_size"
echo "dir_size $dir_size"
echo "outdir $OUTFILE"

# Cleanup
rm -rf $APP_DIR
