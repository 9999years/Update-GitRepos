#Update-GitRepos

`Update-GitRepos` is a PowerShell module that makes keeping all of your git repos up to date easy.

As of the writing of this page, `Update-GitRepos` is **not** a PowerShell module that **works**. Use it at your own risk!

In its simplest form, it iterates through the paths you provide in `GitRepos.txt` and runs `git status --short`, `git pull`, and `git push` on each.

Additionally, an `-Interactive` flag lets you make simple commits.

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

You can render this graph with `make`, provided you have [Graph-Easy](http://search.cpan.org/~tels/Graph-Easy/lib/Graph/Easy.pm) installed.
