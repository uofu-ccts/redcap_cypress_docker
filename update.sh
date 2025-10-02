#!/usr/bin/env bash

# The following line is important to ensure this script stops if any repos have outstanding changes that would prevent a git pull.
set -e

getUpdateScriptInfo () {
  ls -l update.sh
}

oldUpdateScriptInfo=`getUpdateScriptInfo`

echo Updating redcap_cypress_docker...
git pull
git fetch https://github.com/uofu-ccts/redcap_cypress_docker utah-v15.5.7
commitsBehindMain=`git log --oneline ..FETCH_HEAD | wc -l`
if [ $commitsBehindMain != 0 ]; then
    echo
    echo Please either checkout the utah-v15.5.7 branch for redcap_cypress_docker, or merge it into your working branch.
    exit
fi

if [ "$oldUpdateScriptInfo" != "`getUpdateScriptInfo`" ]; then
    echo A changed to update.sh was detected.  Restarting this script...
    ./update.sh
    exit
fi

echo Updating redcap_rsvc...
cd redcap_cypress/redcap_rsvc
git fetch https://github.com/uofu-ccts/redcap_rsvc utah-v15.5.7
rsvcBranchName=`git rev-parse --abbrev-ref HEAD`
if [ "$rsvcBranchName" = "staging" ] || [ "$rsvcBranchName" = "main" ] || [ "$rsvcBranchName" = "utah-v15.5.7" ]; then
    # Developers shouldn't be working directly these branches.
    # This may be an initial run before any development has started.
    # Regardless, just checkout the latest
    git -c advice.detachedHead=false checkout FETCH_HEAD > /dev/null
else
    commitsBehindStaging=`git log --oneline ..FETCH_HEAD | wc -l`
    if [ $commitsBehindStaging != 0 ]; then
        set +x
        echo
        echo Please merge the latest from the 'utah-v15.5.7' branch into your redcap_rsvc branch.
        echo This is not performed automatically to avoid interfering with any active development. 
        exit
    fi
fi
cd ../..

echo Updating redcap_cypress...
cd redcap_cypress
git pull
git fetch https://github.com/uofu-ccts/redcap_cypress utah-v15.5.7
commitsBehindMaster=`git log --oneline ..FETCH_HEAD | wc -l`
if [ $commitsBehindMaster != 0 ]; then
    echo
    echo Please either checkout the utah-v15.5.7 branch for redcap_cypress, or merge it into your working branch.
    exit
fi

# Adam Lewis had an instance where cypress started throwing confusing errors on every feature which was resolved by the following steps:
rm -r node_modules
npm cache clean --force
npm install --no-fund --no-audit
cd ..

echo Updating redcap_docker...
cd redcap_docker
git pull
git fetch https://github.com/uofu-ccts/redcap_docker utah-v15.5.7
commitsBehindMain=`git log --oneline ..FETCH_HEAD | wc -l`
if [ $commitsBehindMain != 0 ]; then
    echo
    echo Please either checkout the utah-v15.5.7 branch for redcap_docker, or merge it into your working branch.
    exit
fi
docker compose --profile external-storage --profile sftp down # This ensures a running container is restarted, which can fix various docker issues.
docker compose up -d --build --remove-orphans # This ensures the container is rebuilt to include any Dockerfile changes, other updates, or fix various issues.

echo
echo 'Update completed successfully!'