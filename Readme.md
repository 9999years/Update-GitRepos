#Update-GitRepos

`Update-GitRepos` is a PowerShell module that makes keeping all of your git repos up to date easy.

New feature: As far as I know, this script now does what it says it does!

In its simplest form, it iterates through the paths you provide in `GitRepos.txt` and runs `git status --short`, `git pull`, and `git push` on each.

Additionally, an `-Interactive` flag lets you make simple commits.

Finding output too slow? Call `Update-GitRepos` with `-Local` to skip the `git pull` and `git push`, just for making commits (with `-Interactive`) or observing which directories need to be worked with.

Program flow in interactive mode:

```
+--------------+  No     +-------------------------------+
|     Quit     | <------ |            Commit?            |
+--------------+         +-------------------------------+
                           |
                           | Yes
                           v
+--------------+  No     +-------------------------------+
|   Use `.`    | <------ |  Add files: Custom pathspec?  |
+--------------+         +-------------------------------+
  |                        |
  |                        | Yes
  |                        v
  |                      +-------------------------------+
  |                      |        Input pathspec         |
  |                      +-------------------------------+
  |                        |
  |                        |
  |                        v
  |                      +-------------------------------+
  +--------------------> |        `git add $Path`        |
                         +-------------------------------+
                           |
                           |
                           v
+--------------+  Long   +-------------------------------+
| `git commit` | <------ | Long or short commit message? |
+--------------+         +-------------------------------+
                           |
                           | Short
                           v
                         +-------------------------------+
                         |     Input commit message      |
                         +-------------------------------+
                           |
                           |
                           v
                         +-------------------------------+
                         |   `git commit -m $Message`    |
                         +-------------------------------+
                           |
                           |
                           v
                         +-------------------------------+
                         |             Done              |
                         +-------------------------------+
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
* Refinement.

##Pull request policy

Please send me pull requests.
