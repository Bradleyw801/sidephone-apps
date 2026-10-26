# Sends new Tyle builds to Brad White's apps (github.com/Bradleyw801/sidephone-apps).
# Start it with PUBLISH-TO-APP-PACK.cmd. Slickrock Station and RetroArch for Slickrock are
# not sent from here: the repository's workflow takes them from their GitHub releases
# (github.com/Bradleyw801/slickrock-releases).
#
# It finds the newest APK of each app in its usual Downloads folder, skips anything the
# pack already serves, asks before sending each new one, and waits until the pack has
# been rebuilt. GitHub then checks every build (signing key, higher version) before it
# goes out, so a wrong build is refused instead of breaking updates on people's phones.
#
# The first run asks for a GitHub token and keeps it encrypted for this Windows account
# only (%LOCALAPPDATA%\SidephoneAppPack\github-token.dat). Delete that file to re-enter it.

param(
    [string]$Downloads,
    [string]$Api = 'https://api.github.com/repos/Bradleyw801/sidephone-apps',
    [string]$Index = 'https://bradleyw801.github.io/sidephone-apps/repo/index-v2.json',
    [string]$TokenFile,
    [int]$PollSeconds = 15,
    [switch]$Yes
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
} catch { }

if (-not $Downloads) { $Downloads = Join-Path $env:USERPROFILE 'Downloads' }
if (-not $TokenFile) { $TokenFile = Join-Path (Join-Path $env:LOCALAPPDATA 'SidephoneAppPack') 'github-token.dat' }

# A source with Patch = $true goes out with the .patch of the same name (for GPL apps).
$Sources = @(
    @{ App = 'Tyle'; Package = 'app.tileshift'; Dir = @('Personal', 'Devices', 'Sidephone'); Pattern = 'Tyle-*.apk' }
    @{ App = 'Twyn'; Package = 'com.bradwhite.twyn'; Dir = @('Personal', 'Devices', 'Sidephone'); Pattern = 'Twyn-*.apk' }
)

$TokenPage = 'https://github.com/settings/personal-access-tokens/new' +
    '?name=Sidephone+app+pack+publisher' +
    '&description=Lets+PUBLISH-TO-APP-PACK+send+new+builds+to+Bradleyw801%2Fsidephone-apps' +
    '&target_name=Bradleyw801&expires_in=none&contents=write&actions=read'

function Say([string]$Text, [string]$Color = 'Gray') { Write-Host $Text -ForegroundColor $Color }

function Finish([int]$Code) {
    Write-Host ''
    if (-not $Yes) { [void](Read-Host 'Press Enter to close') }
    exit $Code
}

function Get-StatusCode($ErrorRecord) {
    try { return [int]$ErrorRecord.Exception.Response.StatusCode } catch { return 0 }
}

function Get-Headers([string]$Token) {
    return @{ Authorization = "Bearer $Token"; 'X-GitHub-Api-Version' = '2022-11-28' }
}

function Invoke-Api([string]$Method, [string]$Uri, [string]$Token, [string]$Body) {
    $p = @{ Method = $Method; Uri = $Uri; Headers = (Get-Headers $Token); UseBasicParsing = $true; UserAgent = 'sidephone-app-pack-publisher'; TimeoutSec = 600 }
    if ($Body) { $p.Body = $Body; $p.ContentType = 'application/json' }
    return Invoke-RestMethod @p
}

function Read-SavedToken {
    if (-not (Test-Path -LiteralPath $TokenFile)) { return $null }
    try {
        $secure = (Get-Content -LiteralPath $TokenFile -Raw).Trim() | ConvertTo-SecureString
        return (New-Object System.Net.NetworkCredential('', $secure)).Password
    } catch {
        return $null
    }
}

function New-Token {
    Say ''
    Say 'This needs a GitHub token that can add files to sidephone-apps (one time only).' White
    Say '  1. A GitHub page is opening with the token already filled in.'
    Say '  2. Under "Repository access" choose "Only select repositories" and pick sidephone-apps.'
    Say '  3. Click "Generate token", copy the token, and paste it here.'
    Say '  It is stored encrypted for your Windows account, so you will not be asked again.'
    try { Start-Process $TokenPage } catch { Say "  Open this page yourself: $TokenPage" Yellow }
    while ($true) {
        $secure = Read-Host 'Token' -AsSecureString
        $token = (New-Object System.Net.NetworkCredential('', $secure)).Password.Trim()
        if (-not $token) { continue }
        # Prove it can write: a blob nothing points to changes nothing in the repository.
        try {
            [void](Invoke-Api 'Post' "$Api/git/blobs" $token '{"encoding":"utf-8","content":"token check"}')
        } catch {
            $code = Get-StatusCode $_
            Say "  GitHub refused that token (HTTP $code). Check that sidephone-apps is selected and Contents is ""Read and write"", then paste it again." Yellow
            continue
        }
        $dir = Split-Path -Parent $TokenFile
        if ($dir -and -not (Test-Path -LiteralPath $dir)) { [void](New-Item -ItemType Directory -Path $dir -Force) }
        (ConvertFrom-SecureString $secure) | Set-Content -LiteralPath $TokenFile -Encoding ASCII
        Say '  Token saved.' Green
        return $token
    }
}

function Get-PublishedHashes {
    $set = @{}
    $idx = Invoke-RestMethod -UseBasicParsing -Uri ($Index + '?t=' + [DateTime]::UtcNow.Ticks)
    foreach ($p in $idx.packages.PSObject.Properties) {
        foreach ($v in $p.Value.versions.PSObject.Properties) { $set[[string]$v.Value.file.sha256] = $p.Name }
    }
    return $set
}

# Version name of the newest published build of each package.
function Get-PublishedVersions {
    $names = @{}
    $idx = Invoke-RestMethod -UseBasicParsing -Uri ($Index + '?t=' + [DateTime]::UtcNow.Ticks)
    foreach ($p in $idx.packages.PSObject.Properties) {
        $top = @($p.Value.versions.PSObject.Properties | ForEach-Object { $_.Value.manifest } | Where-Object { $_ }) |
            Sort-Object { [long]$_.versionCode } -Descending | Select-Object -First 1
        if ($top) { $names[$p.Name] = [string]$top.versionName }
    }
    return $names
}

# The first dotted number in a version or file name ('Tyle-1.19.apk' -> 1.19), or $null.
function Get-VersionNumber([string]$Text) {
    if ($Text -match '(\d+(\.\d+){1,3})') {
        try { return [version]($Matches[1]) } catch { }
    }
    return $null
}

function Send-Builds($Builds, [string]$Token) {
    # A tiny write first, so a token that stopped working is caught before a big upload.
    [void](Invoke-Api 'Post' "$Api/git/blobs" $Token '{"encoding":"utf-8","content":"token check"}')
    $entries = @()
    foreach ($b in $Builds) {
        Say ('  Sending {0} ({1:N1} MB)...' -f $b.File.Name, ($b.File.Length / 1MB))
        $b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($b.File.FullName))
        $blob = Invoke-Api 'Post' "$Api/git/blobs" $Token ('{"encoding":"base64","content":"' + $b64 + '"}')
        $b64 = $null
        $entries += @{ path = 'fdroid/incoming/' + $b.File.Name; mode = '100644'; type = 'blob'; sha = $blob.sha }
        if ($b.Patch) {
            Say ('  Sending {0}...' -f $b.Patch.Name)
            $b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($b.Patch.FullName))
            $blob = Invoke-Api 'Post' "$Api/git/blobs" $Token ('{"encoding":"base64","content":"' + $b64 + '"}')
            $b64 = $null
            $entries += @{ path = 'source/' + $b.Patch.Name; mode = '100644'; type = 'blob'; sha = $blob.sha }
        }
    }
    $message = 'Send ' + (($entries | ForEach-Object { $_.path.Split('/')[-1] }) -join ', ') + ' to the app pack'
    # Commit them on top of main. If main moves first (GitHub finishing an earlier publish,
    # say), GitHub answers 422 and the commit is made again on the new main.
    $try = 0
    while ($true) {
        $try++
        $base = (Invoke-Api 'Get' "$Api/git/ref/heads/main" $Token).object.sha
        $baseTree = (Invoke-Api 'Get' "$Api/git/commits/$base" $Token).tree.sha
        # Never commit without the current tree under the new files: that would empty the repository.
        if ($base -notmatch '^[0-9a-f]{40}$' -or $baseTree -notmatch '^[0-9a-f]{40}$') {
            throw "GitHub gave an unexpected answer about main ($base, $baseTree); nothing was changed."
        }
        $tree = Invoke-Api 'Post' "$Api/git/trees" $Token (ConvertTo-Json -Depth 5 -InputObject @{ base_tree = $baseTree; tree = $entries })
        $commit = Invoke-Api 'Post' "$Api/git/commits" $Token (ConvertTo-Json -Depth 5 -InputObject @{ message = $message; tree = $tree.sha; parents = @($base) })
        try {
            [void](Invoke-Api 'Patch' "$Api/git/refs/heads/main" $Token (ConvertTo-Json -InputObject @{ sha = $commit.sha; force = $false }))
            return $commit.sha
        } catch {
            if ((Get-StatusCode $_) -ne 422 -or $try -ge 5) { throw $_ }
            Start-Sleep -Seconds 3
        }
    }
}

function Get-Run([string]$Sha, [string]$Token) {
    try {
        $runs = Invoke-Api 'Get' "$Api/actions/runs?head_sha=$Sha&per_page=10" $Token
        return $runs.workflow_runs | Where-Object { $_.name -eq 'Publish repository' } | Select-Object -First 1
    } catch {
        return $null
    }
}

# ---------------------------------------------------------------------------------------

Say 'Sidephone app pack publisher' Green
Say ''

$token = Read-SavedToken
if (-not $token) { $token = New-Token; Say '' }

# 1. The newest local build of each app.
$candidates = @()
foreach ($s in $Sources) {
    $dir = $Downloads
    foreach ($part in $s.Dir) { $dir = Join-Path $dir $part }
    if (-not (Test-Path -LiteralPath $dir)) { Say ('  {0}: folder not found ({1})' -f $s.App, $dir) DarkGray; continue }
    $file = Get-ChildItem -LiteralPath $dir -Filter $s.Pattern -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $file) { Say ('  {0}: no build in {1}' -f $s.App, $dir) DarkGray; continue }
    $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLower()
    $patchName = $null
    $patch = $null
    if ($s.Patch) {
        $patchName = ([IO.Path]::GetFileNameWithoutExtension($file.Name) + '.patch').ToLower()
        $patch = Get-ChildItem -LiteralPath $dir -File | Where-Object { $_.Name -ieq $patchName } | Select-Object -First 1
    }
    $candidates += [pscustomobject]@{ App = $s.App; Package = $s.Package; File = $file; Hash = $hash; NeedsPatch = [bool]$s.Patch; Patch = $patch; PatchName = $patchName }
}

# 2. What the pack serves now.
try {
    $published = Get-PublishedHashes
} catch {
    Say ("Couldn't read the app pack: " + $_.Exception.Message) Red
    Finish 1
}
$liveNames = @{}
try { $liveNames = Get-PublishedVersions } catch { }
$new = @()
foreach ($c in $candidates) {
    if ($published.ContainsKey($c.Hash)) { Say ('  {0}: {1} is already published' -f $c.App, $c.File.Name) DarkGray; continue }
    # A build published from somewhere else may already be newer than the one here.
    $mine = Get-VersionNumber $c.File.Name
    $live = Get-VersionNumber $liveNames[$c.Package]
    if ($mine -and $live -and $mine -lt $live) {
        Say ('  {0}: {1} is older than the published {2}' -f $c.App, $c.File.Name, $liveNames[$c.Package]) DarkGray
        continue
    }
    $new += $c
}
if ($new.Count -eq 0) {
    Say ''
    Say 'Nothing new to publish.' Green
    Finish 0
}

# 3. Ask about each new build.
Say ''
$send = @()
foreach ($c in $new) {
    if ($c.NeedsPatch -and -not $c.Patch) {
        Say ('{0}: {1} is new, but {2} is not next to it.' -f $c.App, $c.File.Name, $c.PatchName) Yellow
        Say '  RetroArch is GPL, so the patch should be published with the build.' Yellow
        $answer = 'n'
        if (-not $Yes) { $answer = Read-Host '  Publish the build without it? [y/N]' }
        if ($answer -match '^[Yy]') { $send += $c }
        continue
    }
    $what = $c.File.Name
    if ($c.Patch) { $what += ' (with ' + $c.Patch.Name + ')' }
    $answer = 'y'
    if (-not $Yes) { $answer = Read-Host ('{0}: {1} is new. Publish it? [Y/n]' -f $c.App, $what) }
    if ($answer -eq '' -or $answer -match '^[Yy]') { $send += $c }
}
if ($send.Count -eq 0) {
    Say 'Nothing sent.'
    Finish 0
}

# 4. Send them in one commit to fdroid/incoming (a new token is asked for if the saved one stopped working).
Say ''
$sha = $null
for ($attempt = 1; $attempt -le 2 -and -not $sha; $attempt++) {
    try {
        $sha = Send-Builds $send $token
    } catch {
        $code = Get-StatusCode $_
        if ($attempt -eq 1 -and ($code -eq 401 -or $code -eq 403 -or $code -eq 404)) {
            Say "GitHub didn't accept the saved token (HTTP $code)." Yellow
            Remove-Item -LiteralPath $TokenFile -ErrorAction SilentlyContinue
            $token = New-Token
            continue
        }
        Say ('Sending failed: ' + $_.Exception.Message) Red
        Finish 1
    }
}

# 5. Wait for GitHub to vet and publish them.
Say ''
Write-Host 'Sent. GitHub is checking and publishing (usually 2 to 3 minutes)' -NoNewline
$pending = @($send)
$run = $null
$runDoneAt = $null
$deadline = (Get-Date).AddMinutes(15)
while ($pending.Count -gt 0 -and (Get-Date) -lt $deadline) {
    Start-Sleep -Seconds $PollSeconds
    Write-Host '.' -NoNewline
    try { $published = Get-PublishedHashes } catch { continue }
    $pending = @($pending | Where-Object { -not $published.ContainsKey($_.Hash) })
    if ($pending.Count -eq 0) { break }
    $run = Get-Run $sha $token
    if ($run -and $run.status -eq 'completed') {
        if (-not $runDoneAt) { $runDoneAt = Get-Date }
        elseif (((Get-Date) - $runDoneAt).TotalSeconds -gt (8 * $PollSeconds)) { break }
    }
}
Write-Host ''
Say ''
foreach ($b in $send) {
    if ($pending -contains $b) { Say ('  Not published: {0}' -f $b.File.Name) Red }
    else { Say ('  Published: {0} ({1})' -f $b.File.Name, $b.App) Green }
}
if ($pending.Count -gt 0) {
    if (-not $run) { $run = Get-Run $sha $token }
    $url = 'https://github.com/Bradleyw801/sidephone-apps/actions'
    if ($run) { $url = $run.html_url }
    Say ''
    Say "GitHub says why here: $url" Yellow
    Finish 1
}
Say ''
Say "Done. Phones that have the pack get the update on App Library's next refresh." Green
Finish 0
