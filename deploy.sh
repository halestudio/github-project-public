#!/bin/bash
set -e # exit with nonzero exit code if anything fails

# clear and re-create the out directory
rm -rf www || exit 0;
mkdir www;

rm _data.json
# run projects.js to pull the latest data from github Project
node projects.js halestudio | \
  jq -s 'group_by(.column_name) |
    map( { (.[0].column_name|tostring) : .  }) |
    add |
    {
      "To do": ."To do",
      "In progress": ."In progress",
      Done: .Done
    }' \
  > _data.json


rm -r node_modules

# run our compile script, discussed above
harp compile
# go to the out directory and create a *new* Git repo
cd www
git init

# inside this git repo we'll pretend to be a new user
git config user.name "Travis CI"
git config user.email "travis@hale-studio.org"

# The first and only commit to this new Git repo contains all the
# files present with the commit message "Deploy to GitHub Pages".
git add .
git commit -m "Deploy to GitHub Pages"

# Force push from the current repo's dev branch to the remote github.io
# repo's gh-pages branch. (All previous history on the gh-pages branch
# will be lost, since we are overwriting it.) We redirect any output to
# /dev/null to hide any sensitive credential data that might otherwise be exposed.
git push --force --quiet "https://${GH_TOKEN}@${GH_REF}" master:gh-pages > /dev/null 2>&1
