Set-Alias -Name k -Value kubectl
# Set-Alias -Name kns -Value k8s-set-namespace
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
$BLUE = "$([char]27)[94m"
$CYAN = "$([char]27)[96m"
$WHITE = "$([char]27)[0m"

function kube-info {
	$capture = kubectl config get-contexts | Select-String -Pattern "^\*(\s+([^\s])+)+"
	"$($capture.Matches.Groups[1].Captures[0].Value.Trim())/$($capture.Matches.Groups[1].Captures[3].Value.Trim())"
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

function prompt-toggle([string]$feature) {
	
	if(Test-Path "$HOME\.pwsh\.$feature") {
		Remove-Item "$HOME\.pwsh\.$feature"
	} else {
		New-Item -ItemType File -Path "$HOME\.pwsh" -Name ".$feature" | Out-Null
	}
}

function prompt-k8s {
	if(Test-Path "$HOME\.pwsh\.k8s") {
		"$($BLUE)k8s:($RED$(kube-info)$BLUE)$WHITE "
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
		$aheadMatch = $status | Select-String -Pattern "^Your branch .*ahead.*"
		$behindMatch = $status | Select-String -Pattern "^Your branch .*behind.*"
		$cleanMatch = $status | Select-String -Pattern "^nothing to commit, working tree clean$"
		if($aheadMatch.Matches.Count -gt 0) {$up = "󰧆"}
		if($behindMatch.Matches.Count -gt 0) {$down = "󰦸"}
		if($cleanMatch.Matches.Count -eq 0) {$new = "󰓎"}
		"$($BLUE)git:($branchColor$branchName$BLUE)$down$up$new$WHITE "
	} else {
		""
	}
}

function prompt {"$CYAN$(my-loc) $(prompt-git)$(prompt-k8s)$GREEN$('➜ ' * ($nestedPromptLevel + 1))$WHITE"}
