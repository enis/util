#!/bin/bash

# run this from an apache repo root 

if [ "$#" -eq "0" ] ; then
  echo "usage: $0 <commit_text> "
  exit
fi

COMMIT_TEXT=$1

echo "****************************************************"
echo "Greping commit ($COMMIT_TEXT) for Apache branches   ";
echo "****************************************************"

BRANCHES="master branch-1.3 branch-1.2 branch-1.1 branch-1.0 0.98"
VERSIONS="1.3 1.2 1.1 1.0 0.98"

git fetch -t 

echo
echo "BRANCHES:"
for BRANCH in $BRANCHES; do
  echo $BRANCH
  git log origin/$BRANCH | grep $COMMIT_TEXT
done

echo
echo "RELEASES:"
for VERSION in $VERSIONS; do
  TAGS=`git tag | grep "$VERSION\." | grep -v "RC" | grep -v "rc" | grep -v "SNAPSHOT"`

  for TAG in $TAGS; do
    echo "$TAG"
    git log $TAG | grep $COMMIT_TEXT
  done 
done
