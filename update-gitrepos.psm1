#list of git repos
$global:GitRepos = Get-Content GitRepos.txt -Encoding UTF8

#some globals for preferences
$global:UpdateGitReposPreferences = @{
	CommitChoice = "Undefined"
	CustomPathSpec = "Undefined"
	LongCommit = "Undefined"
}

function Get-YesNoResponse {
	#[Y] Yes [A] Yes to all  [N] No  [L] No to all [S] Suspend [?] Help
	[CmdletBinding()]
	Param(
		[String]$Title = "Prompt",
		[String]$Message = "Prompt message",
		[String]$YesText = "Selects 'yes' for this prompt but not for any future instances of this prompt",
		[String]$YesToAllText = "Selects 'yes' for this prompt and for all future instances of this prompt",
		[String]$NoText = "Selects 'no' for this prompt but not for any future instances of this prompt",
		[String]$NoToAllText = "Selects 'no' for this prompt and for all future instances of this prompt"
	)

	$Response = (Get-Host).UI.PromptForChoice(
`		$Title,
		$Message,
		[System.Management.Automation.Host.ChoiceDescription[]](
			(New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", $YesText),
			(New-Object System.Management.Automation.Host.ChoiceDescription "Yes to &all", $YesToAllText),
			(New-Object System.Management.Automation.Host.ChoiceDescription "&No", $NoText),
			(New-Object System.Management.Automation.Host.ChoiceDescription "No to a&ll", $NoToAllText)
			),
		0
	)

	Switch($Response)
	{
		0 { $Response = "Yes" }
		1 { $Response = "YesToAll" }
		2 { $Response = "No" }
		3 { $Response = "NoToAll" }
	}
	Return $Response
}

function Confirm-LongCommit {
	function ReadCommitMessage {
		Write-Output "Please enter a commit message:"
		Write-Output "If you got here accidentally and don't want to make a commit, just enter <<EXIT>> to skip this repository."
		$CommitMessage = (Get-Host).UI.ReadLine()
		If($CommitMessage -eq "<<EXIT>>")
		{
			Break
		}
		git commit -m "$CommitMessage"
	}

	If( ($global:UpdateGitReposPreferences.LongCommit -ne "YesToAll") -and
		($global:UpdateGitReposPreferences.LongCommit -ne "NoToAll") )
	{
		$global:UpdateGitReposPreferences.LongCommit = Get-YesNoResponse `
			-Title "Commit message"`
			-Message "Would you like to use a long commit (``git commit``)? Answer no to enter a short message for ``git commit -m ...``"`
			-YesText "Runs ``git commit`` for a long commit message."`
			-YesToAllText "Selects 'Yes' for all remaining repositories."`
			-NoText "Asks for a short string to be used in a ``git commit -m ...``"`
			-NoToAllText "Selects 'No' for all remaining repositories."
	}

	Switch($global:UpdateGitReposPreferences.LongCommit)
	{
		"Undefined" { Write-Error "Uh oh! Something went wrong!" }
		"Yes" { git commit --verbose }
		"YesToAll" { git commit --verbose }
		"No"
		{
			ReadCommitMessage
		}
		"NoToAll"
		{
			ReadCommitMessage
		}
	}
}

function Confirm-CustomPathSpec {
	function EnterPathspec {
		Write-Output "Please enter a pathspec:"
		$Pathspec = (Get-Host).UI.ReadLine()
	}

	$Pathspec = "."

	If( ($global:UpdateGitReposPreferences.CustomPathSpec -ne "YesToAll") -and
		($global:UpdateGitReposPreferences.CustomPathSpec -ne "NoToAll") )
	{
		$global:UpdateGitReposPreferences.CustomPathSpec = Get-YesNoResponse `
			-Title "Pathspec"`
			-Message "Would you like to use a custom pathspec? Answer no to use the default pathspec, ``.``"`
			-YesText "Uses a custom pathspec before commiting."`
			-YesToAllText "Selects 'Yes' for all remaining repositories."`
			-NoText "Uses ``.`` as the pathspec on all remaining repositories."`
			-NoToAllText "Selects 'No' for all remaining repositories."
	}

	Switch($global:UpdateGitReposPreferences.CustomPathSpec)
	{
		"Undefined" { Write-Error "Uh oh! Something went wrong!" }
		"Yes"
		{
			EnterPathspec
		}
		"YesToAll"
		{
			EnterPathspec
		}
	}

	git add $Pathspec

	Confirm-LongCommit
}

function Confirm-CommitChoice {
	[CmdletBinding()]
	Param(
		$Path
	)

	Write-Output "git diff:"
	git diff

	Write-Output "git diff --staged:"
	git diff --staged

	If( ($global:UpdateGitReposPreferences.CommitChoice -ne "YesToAll") -and
		($global:UpdateGitReposPreferences.CommitChoice -ne "NoToAll") )
	{
		$global:UpdateGitReposPreferences.CommitChoice = Get-YesNoResponse `
			-Title "Unsaved Work"`
			-Message "There's work to be commited in $(Resolve-Path $Path). Would you like to commit it?"`
			-YesText "Prompts for files to add and a message to commit changes before pushing."`
			-YesToAllText "Selects 'Yes' for all remaining repositories."`
			-NoText "Continues on to push and pull existing commits."`
			-NoToAllText "Selects 'No' for all remaining repositories."
	}

	Switch($global:UpdateGitReposPreferences.CommitChoice)
	{
		"Undefined" { Write-Error "Uh oh! Something went wrong!" }
		"Yes" { Confirm-CustomPathSpec }
		"YesToAll" { Confirm-CustomPathSpec }
	}
}

<#
.SYNOPSIS
	Updates (push/pull and optionally add/commit) a list of git repositories specified in GitRepos.txt

.DESCRIPTION
	Runs git pull and then git push in a list of repositories specified in GitRepos.txt
	With -Interactive, also shows a diff, adds files, and makes commits in said repositories.
	With -Local, Update-GitRepos skips the git pull and git push, showing only the status (and, with -Interactive, offering to make commits) to speed up output.

.PARAMETER Interactive
	Offers to make commits in repositories with changes to be commited, staged or unstaged.
	Flow with -Interactive is as follows:

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

.PARAMETER Local
	Skips the git pull and git push, massively speeding up output or in case of lack of internet.

.PARAMETER ResetPreferences
	Clears the keys in $global:UpdateGitReposPreferences and then terminates, in case of unwanted selections.

.FUNCTIONALITY
	Porcelain.

.EXAMPLE
	PS> Update-GitRepos -Interactive -Local
	==== PROCESSING 0: ~\Documents\Powershell Modules\update-gitrepos ====
	M flow.dot
	M flow.txt
	M update-gitrepos.psm1
	git diff:
	C:/Users/wxyz/AppData/Local/Temp/9UOpQa_flow.dot is not a Word Document.
	flow.dot is not a Word Document.
	diff --git a/flow.txt b/flow.txt
	index 9d12840..9dd8c1d 100644
	--- a/flow.txt
	+++ b/flow.txt
	@@ -1,45 +1,57 @@
	-+--------------+  No     +-------------------------------+
	-|     Quit     | <------ |            Commit?            |
	-+--------------+         +-------------------------------+
	-                           |
	-                           | Yes
	-                           v
	-+--------------+  No     +-------------------------------+
	-|   Use `.`    | <------ |  Add files: Custom pathspec?  |
	-+--------------+         +-------------------------------+
	-  |                        |
	-  |                        | Yes
	-  |                        v
	-  |                      +-------------------------------+
	-  |                      |        Input pathspec         |
	-  |                      +-------------------------------+
	-  |                        |
	-  |                        |
	-  |                        v
	-  |                      +-------------------------------+
	-  +--------------------> |        `git add $Path`        |
	-                         +-------------------------------+
	-                           |
	-                           |
	-                           v
	-+--------------+  Long   +-------------------------------+
	-| `git commit` | <------ | Long or short commit message? |
	-+--------------+         +-------------------------------+
	-                           |
	-                           | Short
	-                           v
	-                         +-------------------------------+
	-                         |     Input commit message      |
	-                         +-------------------------------+
	-                           |
	-                           |
	-                           v
	-                         +-------------------------------+
	git diff --staged:

	Unsaved Work
	There's work to be commited in C:\Users\wxyz\Documents\Powershell
	Modules\update-gitrepos. Would you like to commit it?
	[Y] Yes  [A] Yes to all  [N] No  [L] No to all  [?] Help (default is "Y"): a

	Pathspec
	Would you like to use a custom pathspec? The default pathspec is `.`
	[Y] Yes  [A] Yes to all  [N] No  [L] No to all  [?] Help (default is "Y"): n

	Commit message
	Would you like to use a long commit (`git commit`)? Answer no to enter a short
	message for `git commit -m ...`
	[Y] Yes  [A] Yes to all  [N] No  [L] No to all  [?] Help (default is "Y"): w
	[Y] Yes  [A] Yes to all  [N] No  [L] No to all  [?] Help (default is "Y"): ?
	Y - Runs `git commit` for a long commit message.
	A - Selects 'Yes' for all remaining repositories.
	N - Asks for a short string to be used in a `git commit -m ...`
	L - Selects 'No' for all remaining repositories.
	[Y] Yes  [A] Yes to all  [N] No  [L] No to all  [?] Help (default is "Y"): y
	C:/Users/wxyz/AppData/Local/Temp/56OSic_flow.dot is not a Word Document.
	flow.dot is not a Word Document.
	[master 017db06] Fixed Get-YesNoResponse to work w/o enum, docs.
	3 files changed, 170 insertions(+), 60 deletions(-)
	rewrite flow.dot (94%)
	rewrite flow.txt (100%)
#>
function Update-GitRepos {
	[CmdletBinding()]
	Param(
		[Switch]$Interactive,
		[Switch]$ResetPreferences,
		[Switch]$Local
	)

	#Try block allows catching a C-c to change back to the orig directory
	Try {
		If($ResetPreferences)
		{
			$global:UpdateGitReposPreferences = @{
				CommitChoice = "Undefined"
				CustomPathSpec = "Undefined"
				LongCommit = "Undefined"
			}
			Break
		}
		#Remember the current location so we can go back to it
		#When we're done with processing
		Push-Location
		$i = 0
		ForEach($Repo in $global:GitRepos)
		{
			#Ignore commented lines
			If($Repo.StartsWith("#"))
			{
				Continue
			}

			Write-Output "==== PROCESSING ${i}: $Repo ===="
			Try
			{
				Resolve-Path $Repo -ErrorAction Stop > $Null
			}
			Catch
			{
				Write-Output "${i}: $Repo doesn't exist yet. Making it now."
				mkdir $Repo
			}
			Finally
			{
				Set-Location $Repo
			}

			$Status = git status --short
			git status --short
			If($Status -ne $Null)
			{
				Push-Location -StackName ReposWithUnsavedWork
				If($Interactive -eq $True)
				{
					Confirm-CommitChoice $Repo
				}
			}

			If(!$Local)
			{
				git pull
				git push
			}
			$i++
		}
	}

	Finally {
		Pop-Location
	}
}

New-Alias up Update-GitRepos
