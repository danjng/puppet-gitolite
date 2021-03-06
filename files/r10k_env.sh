#!/bin/bash
#
# Creates commitnumbers as lightweight tags named "r/X" where X increases
# monotonically.
#
# Works by creating a GIT_DIR/commitnumbers file that is a list of all
# commit SHA1s where the commitnumber == the line number of the SHA1 in the
# file.
#
# If you're adding commitnumbers to an existing repo, you can jump start it
# (without the tags, but so you don't start at 0), by:
#
# git rev-list --all > $GIT_DIR/commitnumbers
#
# There is no real reason the tags are named "r/X"--feel free to substitute your
# own prefix or drop it all together. That should probably be a config variable.
#

. $(dirname $0)/functions
umask 0022

if [ $(git rev-parse --is-bare-repository) = true ]
then
    REPOSITORY_BASENAME=$(basename "$PWD") 
else
    REPOSITORY_BASENAME=$(basename $(readlink -nf "$PWD"/..))
fi
REPOSITORY_BASENAME=`echo $REPOSITORY_BASENAME |sed 's/.git$//g'`
while read oldrev newrev refname
do
	branch=$(git rev-parse --symbolic --abbrev-ref $refname)
done

full_checkout=`git diff-tree --no-commit-id --name-only  -r ${branch} |grep Puppetfile -c`

if [ "${REPOSITORY_BASENAME}" == "gitolite-admin" ]
then
	exit
fi

if [ "${REPOSITORY_BASENAME}" == "puppet-control" ]
then
	if [ ${full_checkout} -eq 1 ]
	then
		echo Puppetfile has been modified. Updating entire ${branch} environment
		sudo /usr/local/bin/r10k deploy environment ${branch} -vp
	else
		sudo /usr/local/bin/r10k deploy environment ${branch} -v
	fi
else 
	MOD_NAME=`echo ${REPOSITORY_BASENAME}`
	sudo /usr/local/bin/r10k deploy module ${MOD_NAME}
fi

