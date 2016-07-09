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
$UpdateGitReposPreferences = @{
	CommitChoice = [Confirmation]"Undefined"
	CommitChoice = [Confirmation]"Undefined"
}

#ask for commit
#ask to add . ?
#if no, ask for spec to add
#if yes, add
#

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

	#Switch($Response)
	#{
		#"Undefined"
		#{
			#Write-Output "Something almost definitely went wrong. I got undefined!"
		#}
		#"Yes"
		#{
			#Write-Output "Yes!"
		#}
		#"YesToAll"
		#{
			#Write-Output "Yes to all!"
		#}
		#"No"
		#{
			#Write-Output "Nope!"
		#}
		#"NoToAll"
		#{
			#Write-Output "No to all!"
		#}
	#}
}

function Edit-GitRepo {
	[CmdletBinding()]
	Param(
		[Parameter(
			ValueFromPipeline = $True
			)]
		$Paths
	)
}

function Update-GitRepos {
	[CmdletBinding()]
	Param(
		[Switch]$Interactive
	)

	#Try block allows catching a C-c to change back to the orig directory
	Try {
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
