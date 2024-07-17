Set-PSReadlineKeyHandler -Key Tab -Function Complete

Set-Alias -Name k -Value kubectl
# Set-Alias -Name kns -Value k8s-set-namespace     󰊢   󱃾

Set-Alias -Name lunch -Value C:\Users\vu70\git\semignu\lunchtime\LunchTime.Console\bin\Release\net8.0\LunchTime.Console.exe

function start-gremlin {
	& "C:\Program Files\Azure Cosmos DB Emulator\CosmosDB.Emulator.exe" /PartitionCount=100 /EnableGremlinEndpoint
}	

kubectl completion powershell | Out-String | Invoke-Expression
k completion powershell | Out-String | Invoke-Expression

if (Get-Module -ListAvailable -Name posh-git) {
	Import-Module posh-git
}

if(!(Test-Path "$HOME\.pwsh")) {
	New-Item -ItemType Directory -Path "$HOME\.pwsh" | Out-Null
}

function my-loc {"$($executionContext.SessionState.Path.CurrentLocation)".replace("$HOME", '~')}

$RED = "$([char]27)[91m"
$GREEN = "$([char]27)[92m"
$YELLOW = "$([char]27)[93m"
$BLUE = "$([char]27)[94m"
$PURPLE = "$([char]27)[95m"
$CYAN = "$([char]27)[96m"
$WHITE = "$([char]27)[0m"

$BG_RED = "$([char]27)[41m"
$BG_GREEN = "$([char]27)[42m"
$BG_YELLOW = "$([char]27)[43m"
$BG_BLUE = "$([char]27)[44m"
$BG_PURPLE = "$([char]27)[45m"
$BG_CYAN = "$([char]27)[46m"
$BG_WHITE = "$([char]27)[0m"

$START = ""
$SLASH = ""
$END = ""

$TEST = "$RED$START$BG_PURPLE$SLASH$PURPLE$BG_BLUE$SLASH$WHITE$BLUE$END$WHITE HELLO WORLD"

function kube-info {
	$currentContextLine = Get-Content -Raw $HOME\.kube\config | Select-String -Pattern "current-context: (.*)" 
	$currentContext = $currentContextLine.Matches.Groups[1].Captures[0].Value.Trim()
	$currentNamespaceLine = Get-Content -Raw $HOME\.kube\config | Select-String -Pattern "$currentContext.*\n    namespace: (.*)"
	$currentNamespace = $currentNamespaceLine.Matches.Groups[1].Captures[0].Value.Trim()
	return "$currentContext/$currentNamespace"
}

function k8s-set-namespace([string]$namespace) {
	kubectl config set-context --current --namespace=$namespace
}

Class K8sNameSpaces : System.Management.Automation.IValidateSetValuesGenerator {
    [string[]] GetValidValues() {
		$ns = kubectl get namespaces | Select-String -Pattern "^[a-z-]+" -CaseSensitive
        return [string[]] $ns.Matches.value | Select-Object -Skip 1
    }
}

function kns {
	Param(
    [Parameter(Mandatory=$false)]
    [ValidateSet([K8sNameSpaces])]
    [string]
    $namespace
	)
	if (!$namespace) {
		$namespace = "default"
	}
	k8s-set-namespace($namespace)
}

function az-info {
	$profiles = cat $HOME\.azure\azureProfile.json | ConvertFrom-Json
	$defaultProfile = $profiles.subscriptions | Where-Object -Property isDefault -eq True 
	$username = $defaultProfile.user.name
	$pos = $username.IndexOf("@")
	return $username.Substring(0,$pos)
}

function prompt-toggle([string]$feature) {
	
	if(Test-Path "$HOME\.pwsh\.$feature") {
		Remove-Item "$HOME\.pwsh\.$feature"
	} else {
		New-Item -ItemType File -Path "$HOME\.pwsh" -Name ".$feature" | Out-Null
	}
}

function prompt-k8s {
	if((Test-Path "$HOME\.pwsh\.k8s") -And (Test-Path "$HOME\.kube\config")) {
		$info = kube-info
		$color = if ($info -like "*dev*") {$GREEN} else {$RED}
		"$($BLUE)k8s:($color$info$BLUE)$WHITE "
	} else {
		""
	}
}


function prompt-az {
	if((Test-Path "$HOME\.pwsh\.az") -And (Test-Path "$HOME\.azure\azureProfile.json")) {
		$info = az-info
		$color = if ($info -like "*prod*") {$RED} else {$GREEN}
		"$($BLUE)az:($color$info$BLUE)$WHITE "
	} else {
		""
	}
}


function prompt-git {
	if(Test-Path "$HOME\.pwsh\.git") {
		$status = git status 2>$null
		$branch = $status | Select-String -Pattern "^On branch (.*)$"
		if ($branch.Matches.Count -eq 0) { return "" }
		$branchName = $branch.Matches.Groups[1].Value
		$branchColor = $GREEN
		if ($branchName -eq "main" -or $branchName -eq "master") { $branchColor = $RED }
		$aheadMatch = $status | Select-String -Pattern "^Your branch .*(ahead|diverged).*"
		$behindMatch = $status | Select-String -Pattern "^Your branch .*(behind|diverged).*"
		$cleanMatch = $status | Select-String -Pattern "^nothing to commit, working tree clean$"
		if($aheadMatch.Matches.Count -gt 0) {$up = "A"}
		if($behindMatch.Matches.Count -gt 0) {$down = "B"}
		if($cleanMatch.Matches.Count -eq 0) {$new = "*"}
		"$($BLUE)git:($branchColor$branchName$BLUE)$up$down$new$WHITE "
	} else {
		""
	}
}

function prompt {"$CYAN$(my-loc) $(prompt-git)$(prompt-k8s)$(prompt-az)$GREEN$('➜ ' * ($nestedPromptLevel + 1))$WHITE"}
