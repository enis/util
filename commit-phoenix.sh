#! /usr/bin/env bash

# Phoenix-specific script to commit a patch to Apache branches

# branch mapping to as the cherry-pick target
declare -A cp_branches
cp_branches[master]="master";
cp_branches[branch-1]="master";
cp_branches[branch-1.2]="branch-1";
cp_branches[branch-1.1]="branch-1.2";
cp_branches[branch-1.0]="branch-1.1";
cp_branches[0.98]="branch-1.0";

hbase_branches="-HBase-1.1,-HBase-1.0,-HBase-0.98"

commit=true
cp_continue=false
if [ "$1" == "--no-commit" ]; then
  commit=false
elif [ "$1" == "--continue" ]; then
  cp_continue=true
  shift
elif [ $# -lt 3 ]; then
  # if no args specified, show usage
  echo "Usage: commit.sh [--continue] patch_file branches commit_msg <test>"
  echo "       commit.sh --no-commit branches"
  exit
fi

# silly shortcut. I do not want to write bash logic, so this is hard coded
branches=$2
if [ "$branches" == "4.4+" ]; then
  branches="4.x,4.6,4.5,4.4"
elif [ "$branches" == "4.5+" ]; then
  branches="4.x,4.6,4.5"
elif [ "$branches" == "4.6+" ]; then
  branches="4.x,4.6"
elif [ "$branches" == "4.x+" ]; then
  branches="4.x"
fi

patch=$1
branches=("${branches//,/ }") # parse $2 into an array
hbase_branches=("${hbase_branches//,/ }") # declare -a does not work
commit_msg=$3
test_cmd=""

echo $hbase_branches
# expand branches
expanded_branches=""
for branch in $branches; do
  for hbase_branch in $hbase_branches; do
    if [ "$branch" == "4.x" -a $hbase_branch == "-HBase-1.1" ]; then
	    expanded_branches="$expanded_branches,master"
  	else
	    expanded_branches="$expanded_branches,$branch$hbase_branch"
	  fi
  done
done
branches=("${expanded_branches//,/ }")

if [ $# -gt 3 ]; then
  test_cmd=$4
fi

echo_and_run() {
  local CMD=$1;
  echo ">" $CMD;
  $CMD
}

run_or_die() {
  local CMD=$1;
  if [ $# -gt 1 ]; then
    local input=$2
    echo "> $CMD < $input";
    $CMD < $input || exit
  else 
    echo "> $CMD";
    $CMD || exit
  fi
}

apply_patch() {
  patch=$1
  # figure out whether -p0 or -p1
  p="p0"
  if grep -q "diff --git a" $patch; then
    p="p1"
  fi
  run_or_die "patch -$p" "$patch"
}


build_and_test() {
  if [ "$test_cmd" != "" ]; then
    run_or_die "mvn clean install -Dtest=$test_cmd -DskipIntegrationTests"
  else
    run_or_die "mvn clean install -DskipTests -DskipIntegrationTests"
  fi
}

print_latest_commits() {
  echo
  echo "###################################"
  echo "# COMMIT HISTORY FOR BRANCHES"
  echo "###################################"
  for branch in "${!cp_branches[@]}"  #iterate through keys
  do
	echo 
    echo "===> $branch : ";
    git log $branch --oneline | head -n 3
	echo 
  done
}

echo
echo "#####################################################"
echo "# PATCH      : $patch"
echo "# BRANCHES   : $branches"
echo "# COMMIT_MSG : $commit_msg"
echo "# TEST       : $test_cmd"
echo "#####################################################"

# assume clean git checkout
echo 
echo_and_run "git status"
#TODO: if git status is not clean, refuse to run
echo

for branch in $branches; do 
  echo "###################################"
  echo "# COMMITTING TO BRANCH $branch"
  echo "###################################"

  if [ "$cp_continue" == "false" ]; then
    echo_and_run "git checkout $branch"
    run_or_die "git pull --rebase origin $branch"
  fi

  if [ "$commit" == "true" ]; then 
    if [ $branch == "master" ]; then
      apply_patch "$patch"
      build_and_test
      run_or_die "git add ."
      echo "$commit_msg" >/tmp/commit_msg
      run_or_die "git commit -F /tmp/commit_msg"
    else
      if [ "$cp_continue" == "true" ]; then 
        run_or_die "git add ."
        run_or_die "git cherry-pick --continue"
        cp_continue=false
      else
        #run_or_die "git cherry-pick  ${cp_branches[$branch]}"
        run_or_die "git cherry-pick  master"
      fi
      build_and_test
    fi
  fi
done

print_latest_commits

echo
echo "###################################"
echo "# COMMAND FOR PUSHING THE COMMIT"
echo "###################################"
echo 
echo git push origin $branches
echo 
echo 
