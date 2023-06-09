#!/bin/env janet
(defn devnull
  "get the /dev/null equivalent of the current platform as an open file"
  []
  (os/open (if (= :windows (os/which)) "NUL" "/dev/null") :rw))

(defn exec-slurp
   "Read stdout of subprocess and return it trimmed in a string."
   [& args]
   (def proc (os/spawn args :px {:out :pipe}))
   (def out (get proc :out))
   (def buf @"")
   (ev/gather
     (:read out :all buf)
     (:wait proc))
   (string/trimr buf))

(defn git [& args] (sh/exec-slurp "git" ;args))

(defn git/loud [& args] (os/execute ["git" ;args]))

(defn current-branch [] (git "symbolic-ref" "HEAD"))

(defn current-head []
  (first (peg/match ~(capture (to " ")) (git "show-ref" "--heads" (current-branch)))))

(defn current-user
  (def user-email (git "config" "--get" "user.email"))
  (if (= user-email "")
    (os/getenv "USER")
    user-email))

#if [ -z "$(current_head)" ]; then
#  echo "Empty repository; nothing to do" >&2
#  exit 0
#fi
#check_remote || exit 0

#local_commits_ref() {
#  echo "refs/synced_client/${client_name}"
#}

#remote_commits_ref() {
#  echo "refs/synced_remote_client/${remote}/${client_name}"
#}

#local_changes_ref() {
#  echo "refs/synced_changes/${client_name}"
#}

#remote_changes_ref() {
#  echo "refs/synced_remote_changes/${remote}/${client_name}"
#}

#pull_remote_commit() {
#  git fetch "${remote}" "+$(local_commits_ref):$(remote_commits_ref)" 2>/dev/null >&2
#  git fetch "${remote}" "+$(local_changes_ref):$(remote_changes_ref)" 2>/dev/null >&2

#  remote_commit="$(git show-ref $(remote_commits_ref) | cut -d ' ' -f 1)"
#  if [ -z "${remote_commit}" ]; then
#    # There is no remote commit to merge
#    return 0
#  fi

#  local_commit="$(git show-ref $(local_commits_ref) | cut -d ' ' -f 1)"
#  if [ -z "${local_commit}" ]; then
#    if [ -n "$(git status --porcelain)" ]; then
#      # There are local changes that we do not know how to sync
#      echo "Changes to the local client conflict with the remote client" >&2
#      return 1
#    fi
#    git update-ref "$(local_commits_ref)" "$(remote_commits_ref)" 2>/dev/null >&2
#    git update-ref "$(current_branch)" "${remote_commit}^1" 2>/dev/null >&2
#    git checkout HEAD 2>/dev/null >&2
#    return 0
#  fi

#  git merge-base --is-ancestor "${remote_commit}" "${local_commit}" 2>/dev/null >&2
#  if [ "$?" == "0" ]; then
#    # We have already merged the remote commits
#    return 0
#  fi

#  git merge-base --is-ancestor "${local_commit}" "${remote_commit}"  2>/dev/null >&2
#  if [ "$?" == "0" ]; then
#    git update-ref "$(local_commits_ref)" "$(remote_commits_ref)" 2>/dev/null >&2
#    git update-ref "$(current_branch)" "${remote_commit}^1" 2>/dev/null >&2
#    git checkout HEAD 2>/dev/null >&2
#    if [ -n "$(git status --porcelain)" ]; then
#      # There are obsolete local changes that we do need to clear out
#      git reset HEAD ./ 2>/dev/null >&2
#      git checkout -- ./ 2>/dev/null >&2
#      for file in `git status --porcelain | grep '??' | cut -d ' ' -f 2`; do
#        rm "${file}"
#      done
#    fi
#    return 0
#  fi

#  # We have conflicting updates to the client, and the user must manually fix them
#  echo "Conflicting local and remote clients" >&2
#  return 1
#}

## Save the current, committed state of the local client.
##
## The resulting commit forms a history of every commit (including rebases)
## that the local client has made to the current branch since that local
## branch was created.
#save_current_commit() {
#  previous_commits="$(git show-ref $(local_commits_ref) | cut -d ' ' -f 1)"
#  committed_tree=$(git cat-file -p "$(current_branch)" | head -n 1 | cut -d ' ' -f 2)
#  if [ -z "${previous_commits}" ]; then
#    merged_commit=$(git commit-tree -p "$(current_branch)" -m "Save local commits" "${committed_tree}")
#    git update-ref "$(local_commits_ref)" "${merged_commit}" 2>/dev/null >&2
#  fi
#  git merge-base --is-ancestor "$(current_branch)" "$(local_commits_ref)" 2>/dev/null >&2
#  if [ "$?" != "0" ]; then
#    # The local branch has been updated since we last saved the committed state.
#    # We need to update the commits ref to include this change in our history.
#    merged_commit=$(git commit-tree -p "$(current_branch)" -p "$(local_commits_ref)" -m "Save local commits" "${committed_tree}")
#    git update-ref "$(local_commits_ref)" "${merged_commit}" 2>/dev/null >&2
#  fi
#}

#push_current_commit() {
#  remote_commit="$(git show-ref $(remote_commits_ref) | cut -d ' ' -f 1)"
#  result="1"
#  if [ -n "${remote_commit}" ]; then
#    git push "${remote}" --force-with-lease="$(local_commits_ref):${remote_commit}" "$(local_commits_ref):$(local_commits_ref)" 2>/dev/null >&2
#    result="$?"
#  else
#    git push "${remote}" "$(local_commits_ref):$(local_commits_ref)" 2>/dev/null >&2
#    result="$?"
#  fi
#  if [ "${result}" != "0" ]; then
#    echo "Failed to push the committed local client state to the remote" >&2
#    return 1
#  fi
#}

## Make the local file system match the file tree in the commit at $(local_changes_ref).
##
## This is the logical inverse of `save_changes`
#replay_changes() {
#  maindir=$(pwd)
#  tempdir=$(mktemp -d 2>/dev/null || mktemp -d -t 'sync-changes')
#  git worktree add --no-checkout "${tempdir}" 2>/dev/null >&2
#  cd "${tempdir}"
#  tempbranch="$(current_branch)"

#  git checkout "$(local_changes_ref)" 2>/dev/null >&2
#  find . -not -path './.git/*' -and -not -name '.git' -and -type d -exec  mkdir -p "${maindir}/{}" \;
#  find . -not -path './.git/*' -and -not -name '.git' -and -not -type d -exec cp "${tempdir}/{}" "${maindir}/{}" \;

#  cd "${maindir}"
#  find . -not -path './.git/*' -and -not -name '.git' -and -not -type d -exec bash -c "if [ ! -e '${tempdir}/{}' ] && [ -z \"$(git check-ignore {})\" ]; then rm '{}'; fi" \;
#  rm -rf "${tempdir}"  
#  git update-ref -d "${tempbranch}" 2>/dev/null >&2
#  git worktree prune 2>/dev/null >&2
#}

## Merge saved changes from the remote to our local changes.
##
## This method enforces the following constraints; after the method returns.
## 1. The commit at $(local_changes_ref) (if it exists) contains all
##    changes that were made either locally or remotely after the branch was
##    changed to its current value.
## 2. The local client's files (except for ignored files) match the tree
##    in the commit at $(local_changes_ref) (if it exists).
#merge_remote_changes() {
#  local_ref="$(local_changes_ref)"
#  remote_ref="$(remote_changes_ref)"
#  local_commit="$(git show-ref ${local_ref} | cut -d ' ' -f 1)"
#  remote_commit="$(git show-ref ${remote_ref} | cut -d ' ' -f 1)"

#  if [ -z "${remote_commit}" ]; then
#    # There are no remote changes to merge.
#    return 0
#  fi

#  git merge-base --is-ancestor "$(local_commits_ref)" "${remote_commit}" 2>/dev/null >&2
#  if [ "$?" != "0" ]; then
#    # The remote changes are out of date, so do not pull them down.
#    # (But still allow our local, up to date changes to be pushed back)
#    return 0
#  fi

#  if [ -z "${local_commit}" ]; then
#    # We have no local modifications, so copy the remote ones as-is
#    git update-ref "${local_ref}" "${remote_commit}" 2>/dev/null >&2
#    diff="$(git diff $(local_commits_ref)..${remote_commit})"
#    if [ -n "${diff}" ]; then
#      echo "${diff}" | git apply --
#    fi
#    return 1
#  elif [ "${local_commit}" == "${remote_commit}" ]; then
#    # Everything is already in sync.
#    return 1
#  fi

#  if [ -n "${local_commit}" ]; then
#    merge_base="$(git merge-base ${local_ref} ${remote_ref})"
#    if [ "${remote_commit}" == "${merge_base}" ]; then
#      # The remote changes have already been included in our local changes.
#      # All that is left is for us to potentially push the local changes.
#      return 0
#    fi
#  fi

#  # Create a temporary directory in which to perform the merge
#  maindir=$(pwd)
#  tempdir=$(mktemp -d 2>/dev/null || mktemp -d -t 'sync-changes')
#  git worktree add "${tempdir}" 2>/dev/null >&2
#  cd "${tempdir}"

#  # Perform the merge, favoring our changes in the case of conflicts, and
#  # update the local ref.
#  if [ -n "${local_commit}" ]; then
#    git merge --ff -s recursive -X theirs "${local_ref}" 2>/dev/null >&2
#  fi
#  git merge --ff -s recursive -X ours "${remote_ref}" 2>/dev/null >&2
#  git add ./
#  git commit -a -m "Merge remote changes" 2>/dev/null >&2
#  tempbranch="$(current_branch)"
#  git update-ref "${local_ref}" "${tempbranch}" 2>/dev/null >&2

#  # Cleanup post merge
#  cd "${maindir}"
#  rm -rf "${tempdir}"
#  git update-ref -d "${tempbranch}"
#  git worktree prune

#  # Copy any remote changes to our working dir
#  replay_changes
#  return 0
#}

#push_local_changes() {
#  local_ref="$(local_changes_ref)"
#  remote_ref="$(remote_changes_ref)"
#  remote_commit="$(git show-ref ${remote_ref} | cut -d ' ' -f 1)"

#  if [ -z "$(git show-ref ${local_ref})" ]; then
#    # We have reset our history locally and not retrieved any up-to-date history from
#    # the remote, so reset the change history on the remote
#    git push "${remote}" --force-with-lease="${local_ref}:${remote_commit}" --delete "${local_ref}" 2>/dev/null >&2
#    git update-ref -d "${remote_ref}"
#    return 0
#  fi

#  git push "${remote}" --force-with-lease="${local_ref}:${remote_commit}" "${local_ref}:${local_ref}" 2>/dev/null >&2 || return 0
#}

## Create an undo-buffer-like commit of the local changes.
##
## This differs from `git stash` in that multiple changes can
## be chained together.
##
## The resulting commit is stored in $(local_changes_ref)
##
## This method enforces two constraints; after the method returns:
## 1. The contents of the local client's files (other than ignored files)
##    matches the tree of the commit stored at $(local_changes_ref),
##    if it exists.
## 2. The history of the commit stored at $(local_changes_ref),
##    if it exists, includes every change that was saved since HEAD
##    was changed to its current value.
#save_changes() {
#  saved_changes_commit="$(git show-ref $(local_changes_ref) | cut -d ' ' -f 1)"
#  if [ -n "${saved_changes_commit}" ]; then
#    git merge-base --is-ancestor "$(local_commits_ref)" "$(local_changes_ref)" 2>/dev/null >&2
#    if [ "$?" != "0" ]; then
#      # The local branch has been updated since our last save. We need
#      # to clear out the (now obsolete) saved changes.
#      git update-ref -d "$(local_changes_ref)"
#      saved_changes_commit=""
#    fi
#  fi

#  current_changes="$(git status --porcelain)"
#  if [ -z "${saved_changes_commit}" ] && [ -z "${current_changes}" ]; then
#    # We have neither local modifications nor previously saved changes
#    return 0
#  fi
#  if [ -z "${current_changes}" ]; then
#    # We undid previous changes, so we need to create a commit to record that
#    changes_tree=$(git cat-file -p "$(local_commits_ref)" | head -n 1 | cut -d ' ' -f 2)
#    changes_commit=$(git commit-tree -p "${saved_changes_commit}" -m "Save local changes" "${changes_tree}")
#    git update-ref "$(local_changes_ref)" "${changes_commit}" 2>/dev/null >&2
#    return 0
#  fi

#  if [ -z "${saved_changes_commit}" ]; then
#    saved_changes_commit="$(local_commits_ref)"
#  fi

#  # Create a temporary directory in which to create the changes commit
#  maindir=$(pwd)
#  tempdir=$(mktemp -d 2>/dev/null || mktemp -d -t 'sync-changes')
#  git worktree add --no-checkout "${tempdir}" 2>/dev/null >&2
#  find . -not -path './.git/*' -and -not -name '.git' -and -type d -exec mkdir -p "${tempdir}/{}" \;
#  find . -not -path './.git/*' -and -not -name '.git' -and -not -type d -exec cp "{}" "${tempdir}/{}" \;
#  cd "${tempdir}"
#  tempbranch="$(current_branch)"
#  git add ./

#  if [ -n "$(git diff ${saved_changes_commit} -- ./)" ]; then
#    # We have changes since the last time we saved.
#    git commit -a -m "Save local changes" 2>/dev/null >&2
#    changes_tree=$(git cat-file -p "${tempbranch}" | head -n 1 | cut -d ' ' -f 2)
#    changes_commit=$(git commit-tree -p "${saved_changes_commit}" -m "Save local changes" "${changes_tree}")
#    git update-ref "$(local_changes_ref)" "${changes_commit}" 2>/dev/null >&2
#  fi

#  # Cleanup post merge
#  cd "${maindir}"
#  rm -rf "${tempdir}"
#  git update-ref -d "${tempbranch}"
#  git worktree prune
#}

(defn check-remote []
  (def status-code (os/execute ["git" "remote" "get-url" remote]))
  (if (= status-code 0) true (do (print "Remote " remote "does not exist... nothing to sync") false)))

(defn main [myself & args]
  (def remote (if (first args) (first args) "origin"))
  (def client_name (if (get args 1 nil) (get args 1 nil) (string (current-user) "/" (current-branch))))
  (if (not (pull-remote-commit)) (os/exit 1))
  (save-current-commit)
  (if (not (push-current-commit)) (os/exit 1))
  (save-changes)
  (if (not (merge-remote-changes)) (os/exit 0))
  (push-local-changes))
