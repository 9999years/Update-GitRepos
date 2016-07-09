#list of git repos
$GitRepos = Get-Content .\GitRepos.txt -Encoding UTF8

function Update-GitRepos {
	[CmdletBinding()]
	Param(
		[Switch]$Interactive
	)

	#Try block allows catching a C-c to change back to the orig directory
	Try {
		Enum
		{
			Undefined = -1
			Yes,
			YesToAll,
			No,
			NoToAll
		}

		#[Y] Yes [A] Yes to all  [N] No  [L] No to all [S] Suspend [?] Help
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

			Write-Output "PROCESSING ${i}: $Repo"
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
					If(($CommitChoice -ne [Confirmation]"YesToAll") && ($CommitChoice -ne [Confirmation]"NoToAll"))
					{
						[Confirmation]$CommitChoice = (Get-Host).UI.PromptForChoice(
							"Unsaved Work",
							"There's unsaved work in this repo. Would you like to make a commit?",
							[System.Managment.Automation.Host.ChoiceDescription[]](
								(New-Object System.Managment.Automation.Host.ChoiceDescription "&Yes", "Prompts for files to add and a message to commit changes before pushing."),
								(New-Object System.Managment.Automation.Host.ChoiceDescription "Yes to &all", "Selects 'Yes' for all remaining repositories."),
								(New-Object System.Managment.Automation.Host.ChoiceDescription "&No", "Continues on to push and pull existing commits."),
								(New-Object System.Managment.Automation.Host.ChoiceDescription "No to a&ll", "Selects 'No' for all remaining repositories."),
								),
							0
							)
						Switch($CommitChoice)
						{
							"Yes"
							{

							}
						}
					}
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
