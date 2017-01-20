#list of git repos
$global:GitReposPath = "$PSScriptRoot\repos\GitRepos.txt"

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
	function EnterPathSpec {
		Write-Output "Please enter a pathspec:"
		$PathSpec = (Get-Host).UI.ReadLine()
	}

	$PathSpec = "."

	If( ($global:UpdateGitReposPreferences.CustomPathSpec -ne "YesToAll") -and
		($global:UpdateGitReposPreferences.CustomPathSpec -ne "NoToAll") )
	{
		$global:UpdateGitReposPreferences.CustomPathSpec = Get-YesNoResponse `
			-Title "PathSpec"`
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
			EnterPathSpec
		}
		"YesToAll"
		{
			EnterPathSpec
		}
	}

	git add $PathSpec

	Confirm-LongCommit
}

function Confirm-CommitChoice {
	[CmdletBinding()]
	Param(
		$Path
	)

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
	Flow with -Interactive can be viewed in flow.txt in the module directory.

.PARAMETER Local
	Skips the git pull and git push, massively speeding up output or in case of lack of internet.

.PARAMETER ResetPreferences
	Clears the keys in $global:UpdateGitReposPreferences and then terminates, in case of unwanted selections.

.LINK
	https://github.com/9999years/update-gitrepos

.NOTES
	Additional help and instructions can be found in Readme.md, contained in the module directory.
#>
function Update-GitRepos {
	[CmdletBinding()]
	Param(
		[Switch]$Interactive,
		[Switch]$ResetPreferences,
		[Switch]$Local
	)

	$GitRepos = Get-Content $global:GitReposPath -Encoding UTF8

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

		If($GitRepos -eq $Null)
		{
			Write-Output "No repos found in ``$($global:GitReposPath)``! Quitting"
		}

		#Remember the current location so we can go back to it
		#When we're done with processing
		Push-Location -StackName "UpdateGitRepos"
		$i = 0
		ForEach($RepoLine in GitRepos)
		{
			#Ignore commented lines
			If($RepoLine.StartsWith("#"))
			{
				Continue
			}

			ForEach($Repo in (Resolve-Path $RepoLine))
			{
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
					Push-Location -StackName "UnsavedWork"
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
	}

	Finally {
		Pop-Location -StackName "UpdateGitRepos"
	}
}
