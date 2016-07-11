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

function Confirm-CustomPathSpec {
	[CmdletBinding()]
	Param(
		$Paths
	)

	$Pathspec = "."

	If( ($global:UpdateGitReposPreferences.CustomPathSpec -ne [Confirmation]"YesToAll") -and
		($global:UpdateGitReposPreferences.CustomPathSpec -ne [Confirmation]"NoToAll") )
	{
		$global:UpdateGitReposPreferences.CustomPathSpec = Get-YesNoResponse`
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
			Write-Output "Please enter a pathspec:"
			$Pathspec = (Get-Host).UI.ReadLine()
		}
		"YesToAll"
		{
			Write-Output "Please enter a pathspec:"
			$Pathspec = (Get-Host).UI.ReadLine()
		}
	}

	git add $Pathspec
}

function Confirm-CommitChoice {
	[CmdletBinding()]
	Param(
		$Path
	)

	If( ($global:UpdateGitReposPreferences.CommitChoice -ne [Confirmation]"YesToAll") -and
		($global:UpdateGitReposPreferences.CommitChoice -ne [Confirmation]"NoToAll") )
	{
		$global:UpdateGitReposPreferences.CommitChoice = Get-YesNoResponse`
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
		[Switch]$ResetPreferences
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
			If($Status -ne $Null)
			{
				Push-Location -StackName ReposWithUnsavedWork
				If($Interactive -eq $True)
				{
					#If(($CommitChoice -ne [Confirmation]"YesToAll") && ($CommitChoice -ne [Confirmation]"NoToAll"))
					#{
						#Switch($CommitChoice)
						#{
							#"Yes"
							#{

							#}
						#}
					#}
				}
			}


			git status --short
			git pull
			git push
			$i++
		}
	}

	Finally {
		Pop-Location
	}
}

New-Alias up Update-GitRepos
