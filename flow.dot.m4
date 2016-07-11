changequote({{,}})

define({{commit_label}}, {{"Commit?"}})
define({{add_label}}, {{"Add files: Custom pathspec?"}})
define({{quit}}, {{"Quit"}})
define({{input_pathspec}}, {{"Input pathspec"}})
define({{input_pathspec}}, {{"Input pathspec"}})
define({{quit}},{{"Quit"}})
define({{git_add}},{{"`git add $Path`"}})
define({{use_dot}},{{"Use `.`"}})

define({{[no]}},{{[label="No"]}})
define({{[yes]}},{{[label="Yes"]}})

digraph programflow {

	commit_label -> add_label [yes]

	commit_label -> quit [no]

	add_label -> input_pathspec [yes]

	add_label -> use_dot [no]

	use_dot -> "'git add $Path'"
	"Input pathspec" -> "'git add $Path'"

	"'git add $Path'" -> "Long or short commit message?" -> "'git commit'" [label="Long"]
	"Long or short commit message?" -> "Input commit message" [label="Short"]

	"Input commit message" -> "'git commit -m $Message'" -> "Done"
}
