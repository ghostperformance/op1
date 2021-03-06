#!/usr/bin/bash -e

if [ -z "$SOURCE_DIR" ]; then
  echo "SOURCE_DIR must be set"
  exit 1
fi

if [ -z "$GIT_COMMIT" ]; then
  echo "GIT_COMMIT must be set"
  exit 1
fi

if [ -z "$TEST_DIR" ]; then
  echo "TEST_DIR must be set"
  exit 1
fi

# setup jenkins device
if [ ! -d "$SOURCE_DIR" ]; then
  # write continue.sh
  CONTINUE_FILE="/data/data/com.termux/files/continue.sh"
  echo "#!/usr/bin/bash" > $CONTINUE_FILE
  echo "wpa_cli IFNAME=wlan0 SCAN" >> $CONTINUE_FILE
  echo "sleep infinity" >> $CONTINUE_FILE

  # write SSH keys
  curl "https://github.com/commaci2.keys" > /data/params/d/GithubSshKeys

  git clone --depth 1 https://github.com/commaai/openpilot.git "$SOURCE_DIR"
fi

if [ -f "/EON" ]; then
  rm -rf /data/core
  rm -rf /data/neoupdate
  rm -rf /data/safe_staging
fi

# set up environment
cd $SOURCE_DIR
git reset --hard
git fetch
find . -maxdepth 1 -not -path './.git' -not -name '.' -not -name '..' -exec rm -rf '{}' \;
git reset --hard $GIT_COMMIT
git checkout $GIT_COMMIT
git clean -xdf
git submodule update --init --recursive
git submodule foreach --recursive git reset --hard
git submodule foreach --recursive git clean -xdf
echo "git checkout took $SECONDS seconds"

rsync -a --delete $SOURCE_DIR $TEST_DIR

echo "$TEST_DIR synced with $GIT_COMMIT, took $SECONDS seconds"
