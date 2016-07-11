Enum Confirmation
{
	Undefined = -1
	Yes
	YesToAll
	No
	NoToAll
}

#list of git repos
$GitRepos = Get-Content .\GitRepos.txt -Encoding UTF8

#some globals for preferences
$global:UpdateGitReposPreferences = @{
	CommitChoice = [Confirmation]"Undefined"
	CustomPathSpec = [Confirmation]"Undefined"
	LongOrShortCommit = [Confirmation]"Undefined"
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

	[Confirmation]$Response = (Get-Host).UI.PromptForChoice(
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
	Return $Response
}

function Confirm-LongOrShortCommit {
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

	If( ($global:UpdateGitReposPreferences.LongOrShortCommit -ne [Confirmation]"YesToAll") -and
		($global:UpdateGitReposPreferences.LongOrShortCommit -ne [Confirmation]"NoToAll") )
	{
		$global:UpdateGitReposPreferences.LongOrShortCommit = Get-YesNoResponse `
			-Title "Commit message"`
			-Message "Would you like to use a long commit (``git commit``)? Answer no to enter a short message for ``git commit -m ...``"`
			-YesText "Runs ``git commit`` for a long commit message."`
			-YesToAllText "Selects 'Yes' for all remaining repositories."`
			-NoText "Asks for a short string to be used in a ``git commit -m ...``"`
			-NoToAllText "Selects 'No' for all remaining repositories."
	}

	Switch($global:UpdateGitReposPreferences.LongOrShortCommit)
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

	If( ($global:UpdateGitReposPreferences.CustomPathSpec -ne [Confirmation]"YesToAll") -and
		($global:UpdateGitReposPreferences.CustomPathSpec -ne [Confirmation]"NoToAll") )
	{
		$global:UpdateGitReposPreferences.CustomPathSpec = Get-YesNoResponse `
			-Title "Pathspec"`
			-Message "Would you like to use a custom pathspec? The default pathspec is ``.``"`
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

	Confirm-LongOrShortCommit
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

	If( ($global:UpdateGitReposPreferences.CommitChoice -ne [Confirmation]"YesToAll") -and
		($global:UpdateGitReposPreferences.CommitChoice -ne [Confirmation]"NoToAll") )
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
				CommitChoice = [Confirmation]"Undefined"
				CustomPathSpec = [Confirmation]"Undefined"
				LongOrShortCommit = [Confirmation]"Undefined"
			}
		}
		#Remember the current location so we can go back to it
		#When we're done with processing
		Push-Location
		$i = 0
		ForEach($Repo in $GitRepos)
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
