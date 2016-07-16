#Update-GitRepos

`Update-GitRepos` is a PowerShell module that makes keeping all of your git repos up to date easy.

New feature: As far as I know, this script now does what it says it does!

To use, just add `Import-Module ..\path\to\this\repo` to your `$Profile`.

In its simplest form, it iterates through the paths you provide in `GitRepos.txt` and runs `git status --short`, `git pull`, and `git push` on each.

Additionally, an `-Interactive` flag lets you make simple commits.

Finding output too slow? Call `Update-GitRepos` with `-Local` to skip the `git pull` and `git push`, just for making commits (with `-Interactive`) or observing which directories need to be worked with.

You can also set default preferences for the interactive mode prompts by adding (something like) the following to your `$PROFILE`

```
$global:UpdateGitReposPreferences = @{
	CommitChoice = "YesToAll"
	CustomPathSpec = "NoToAll"
	LongCommit = "NoToAll"
}
```

Other possible values for these keys are "Yes", "No", and "Undefined", although changing the keys to any of those won't alter the behavior of the program.

A graph of the program flow in interactive mode follows. After finishing, the program will move onto the next repository and repeat the process, meaning that here “done” and “quit” indicate being finished with the current repository, and not the program as a whole.

```
+--------------------------+     +----------------------------------------+
|            No            | <-- |     Commit? (Confirm-CommitChoice)     |
+--------------------------+     +----------------------------------------+
  |                                |
  |                                |
  v                                v
+--------------------------+     +----------------------------------------+
|           Done           |     |                  Yes                   |
+--------------------------+     +----------------------------------------+
                                   |
                                   |
                                   v
+--------------------------+     +----------------------------------------+
|           Yes            |     |      Add files: Custom pathspec?       |
|                          | <-- | (Confirm-CustomPathspec.EnterPathSpec) |
+--------------------------+     +----------------------------------------+
  |                                |
  |                                |
  v                                v
+--------------------------+     +----------------------------------------+
|      Input pathspec      |     |                   No                   |
| (Confirm-CustomPathSpec) |     |                                        |
+--------------------------+     +----------------------------------------+
  |                                |
  |                                |
  |                                v
  |                              +----------------------------------------+
  |                              |                Use `.`                 |
  |                              +----------------------------------------+
  |                                |
  |                                |
  |                                v
  |                              +----------------------------------------+
  +----------------------------> |            `git add $Path`             |
                                 +----------------------------------------+
                                   |
                                   |
                                   v
+--------------------------+     +----------------------------------------+
|           Long           |     |     Long or short commit message?      |
|                          | <-- |          (Confirm-LongCommit)          |
+--------------------------+     +----------------------------------------+
  |                                |
  |                                |
  v                                v
+--------------------------+     +----------------------------------------+
|       `git commit`       |     |                 Short                  |
+--------------------------+     +----------------------------------------+
                                   |
                                   |
                                   v
                                 +----------------------------------------+
                                 |          Input commit message          |
                                 | (Confirm-LongCommit.ReadCommitMessage) |
                                 +----------------------------------------+
                                   |
                                   |
                                   v
+--------------------------+     +----------------------------------------+
|           Yes            | <-- |         Message == "<<EXIT>>"?         |
+--------------------------+     +----------------------------------------+
  |                                |
  |                                |
  v                                v
+--------------------------+     +----------------------------------------+
|           Done           |     |                   No                   |
+--------------------------+     +----------------------------------------+
                                   |
                                   |
                                   v
                                 +----------------------------------------+
                                 |        `git commit -m $Message`        |
                                 +----------------------------------------+
```

(You can render this graph with `make`, provided you have [Graph-Easy](http://search.cpan.org/~tels/Graph-Easy/lib/Graph/Easy.pm) installed.)

Output from a session in interactive mode with one repository (this one) can look like this:

```
==== PROCESSING 0: ~\Documents\Powershell Modules\update-gitrepos ====

Unsaved Work
There's work to be commited in
C:\Users\wxyz\Documents\Powershell Modules\update-gitrepos.
Would you like to commit it?
[Y] Yes  [A] Yes to all  [N] No  [L] No to all  [?] Help
(default is "Y"):y

Pathspec
Would you like to use a custom pathspec? The default pathspec
 is `.`
[Y] Yes  [A] Yes to all  [N] No  [L] No to all  [?] Help
(default is "Y"):n

Commit message
Would you like to use a long commit (`git commit`)? Answer no
 to enter a short message for `git commit -m ...`
[Y] Yes  [A] Yes to all  [N] No  [L] No to all  [?] Help
(default is "Y"):n
Please enter a commit message:
Possible working beta???
[master 9a6a125] Possible working beta???
 3 files changed, 123 insertions(+), 37 deletions(-)
 rewrite GitRepos.txt (60%)
 create mode 100644 Readme.md
Already up-to-date.
Counting objects: 5, done.
Delta compression using up to 4 threads.
Compressing objects: 100% (5/5), done.
Writing objects: 100% (5/5), 1.45 KiB | 0 bytes/s, done.
Total 5 (delta 3), reused 0 (delta 0)
To https://github.com/9999years/Update-GitRepos.git
   96590ea..9a6a125  master -> master
```

##Features that might be coming soon:

* The ability to “drop out” into another PowerShell instance to run arbitrary commands in any repository when it’s being processed.
* A dry run mode.

##Pull request policy

Please send me pull requests.
