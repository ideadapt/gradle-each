#!/bin/bash


show_help() {
	echo "Usage: $0 --gradle-task assembleDebug --from-hash master --till-hash feature-branch"
}

build_commit() {
	commit=$1
	gradle_tasks=$2

	# Check parameters
	if [[ -z "${commit// }" ]] || [[ -z "${gradle_tasks// }" ]]; then
		echo "Error: Missing arguments in build_commit()."
		exit 1
	fi

	# Commands
	git_short_log_cmd="git log --abbrev-commit --format=oneline -n 1 $commit"
	gradlew_cmd="./gradlew $gradle_tasks"

	echo
	echo "=============================================================================="
	echo "Running Gradle task on \"`$git_short_log_cmd`\" ..."
	echo "=============================================================================="
	echo

	git checkout $commit
	git submodule update

	# Execute Gradle command; store its exit code
	$gradlew_cmd; gradlew_exit_code=$?

	echo
	echo "Gradle task exit code = $gradlew_exit_code"

	if [ "$gradlew_exit_code" -eq "0" ]; then
		echo "Gradle task \"$gradle_tasks\" succeeded."
	else
		echo "Gradle task \"$gradle_tasks\" failed."
		echo "Commit: \"`$git_short_log_cmd`\" ..."
		exit 1
	fi
}

build_commits() {
	gradle_tasks=$1
	from_hash=$2
	till_hash=$3

	# Check parameters
	if [[ -z "${gradle_tasks// }" ]] || [[ -z "${from_hash// }" ]] || [[ -z "${till_hash// }" ]]; then
		echo "Error: Missing arguments in build_commits()."
		exit 1
	fi

	# Commmands
	git_list_commits_hashes_cmd="git rev-list --reverse $from_hash..$till_hash"

	echo "JAVA_HOME = $JAVA_HOME"

	# Iterating all commits
	for commit in $($git_list_commits_hashes_cmd)
	do
		build_commit "${commit}" "${gradle_tasks}"
	done
}




while [[ $# -gt 1 ]]
do
key="$1"

case $key in
    -g|--gradle-tasks)
    GRADLE_TASKS="$2"
    shift # past argument
    ;;
    -f|--from-hash)
    FROM_HASH="$2"
    shift # past argument
    ;;
    -t|--till-hash)
    TILL_HASH="$2"
    shift # past argument
    ;;
    *)
    # unknown option
    ;;
esac
shift # past argument or value
done
echo
echo GRADLE_TASKS  = "${GRADLE_TASKS}"
echo FROM_HASH    = "${FROM_HASH}"
echo TILL_HASH    = "${TILL_HASH}"
echo

if [[ -z "${GRADLE_TASKS// }" ]] || [[ -z "${FROM_HASH// }" ]] || [[ -z "${TILL_HASH// }" ]]; then
	show_help
	exit 0
fi

build_commits "${GRADLE_TASKS}" "${FROM_HASH}" "${TILL_HASH}"

exit 0