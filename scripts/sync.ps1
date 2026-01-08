# my-claude-bible 동기화 스크립트 (Windows PowerShell)

Write-Host "🔄 my-claude-bible 동기화 시작..." -ForegroundColor Cyan
Write-Host ""

# 디렉토리 경로
$ClaudeSkills = "$env:USERPROFILE\.claude\skills"
$RepoDir = "$env:USERPROFILE\my-claude-vible"
$RepoSkills = "$RepoDir\skills"

# 저장소 디렉토리 확인
if (-not (Test-Path $RepoDir)) {
    Write-Host "⚠️  my-claude-vible 디렉토리를 찾을 수 없습니다: $RepoDir" -ForegroundColor Yellow
    Write-Host "먼저 저장소를 클론하세요:"
    Write-Host "  git clone https://github.com/yoosee1219-a11y/my-claude-bible.git $RepoDir"
    exit 1
}

# 저장소로 이동
Set-Location $RepoDir

# 원격 최신 상태 확인
Write-Host "📡 원격 저장소 확인 중..." -ForegroundColor Blue
git fetch origin | Out-Null

# 스킬 파일 동기화
Write-Host ""
Write-Host "📦 스킬 파일 동기화 중..." -ForegroundColor Blue

$SyncedCount = 0
$NewCount = 0
$UpdatedCount = 0

Get-ChildItem "$ClaudeSkills\*.md" -ErrorAction SilentlyContinue | ForEach-Object {
    $SkillName = $_.Name
    $SourcePath = $_.FullName
    $DestPath = "$RepoSkills\$SkillName"

    if (-not (Test-Path $DestPath)) {
        # 새 파일
        Copy-Item $SourcePath $DestPath -Force
        Write-Host "  + $SkillName (새 스킬)" -ForegroundColor Green
        $NewCount++
        $SyncedCount++
    } else {
        # 파일 비교 (해시 사용)
        $SourceHash = (Get-FileHash $SourcePath -Algorithm MD5).Hash
        $DestHash = (Get-FileHash $DestPath -Algorithm MD5).Hash

        if ($SourceHash -ne $DestHash) {
            # 수정된 파일
            Copy-Item $SourcePath $DestPath -Force
            Write-Host "  ✎ $SkillName (수정됨)" -ForegroundColor Cyan
            $UpdatedCount++
            $SyncedCount++
        }
    }
}

# 변경사항 확인
if ($SyncedCount -eq 0) {
    Write-Host ""
    Write-Host "✅ 모든 스킬이 최신 상태입니다!" -ForegroundColor Green
    exit 0
}

# Git 상태 확인
Write-Host ""
Write-Host "📊 변경 사항:" -ForegroundColor Blue
git status --short

# Git에 추가
Write-Host ""
Write-Host "📝 Git에 추가 중..." -ForegroundColor Blue
git add skills/

# 커밋 메시지 생성
$CommitMsg = "Sync skills: "
if ($NewCount -gt 0) {
    $CommitMsg += "$NewCount개 추가"
}
if ($UpdatedCount -gt 0) {
    if ($NewCount -gt 0) {
        $CommitMsg += ", "
    }
    $CommitMsg += "$UpdatedCount개 수정"
}
$CommitMsg += " ($(Get-Date -Format 'yyyy-MM-dd HH:mm'))"

# 커밋
try {
    git commit -m $CommitMsg 2>&1 | Out-Null
} catch {
    Write-Host "ℹ️  커밋할 변경사항이 없습니다" -ForegroundColor Yellow
    exit 0
}

# 푸시
Write-Host ""
Write-Host "🚀 GitHub에 푸시 중..." -ForegroundColor Blue
git push origin main

# 완료
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "✨ 동기화 완료!" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host ""
Write-Host "📊 동기화 요약:" -ForegroundColor Blue
if ($NewCount -gt 0) {
    Write-Host "  • 새로 추가: $NewCount개"
}
if ($UpdatedCount -gt 0) {
    Write-Host "  • 수정됨: $UpdatedCount개"
}
Write-Host "  • 총 동기화: $SyncedCount개"
Write-Host ""
Write-Host "🔗 GitHub: https://github.com/yoosee1219-a11y/my-claude-bible" -ForegroundColor Cyan
Write-Host ""
