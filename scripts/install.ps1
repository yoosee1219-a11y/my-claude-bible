# my-claude-vible 설치 스크립트 (Windows PowerShell)

Write-Host "🚀 my-claude-vible 설치 시작..." -ForegroundColor Cyan
Write-Host ""

# Claude 디렉토리 경로
$ClaudeDir = "$env:USERPROFILE\.claude"
$SkillsDir = "$ClaudeDir\skills"
$AgentsDir = "$ClaudeDir\agents"

# 디렉토리 생성
if (-not (Test-Path $ClaudeDir)) {
    Write-Host "⚠️  .claude 디렉토리가 없습니다. 생성합니다..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $ClaudeDir -Force | Out-Null
}

if (-not (Test-Path $SkillsDir)) {
    Write-Host "📁 .claude\skills 디렉토리 생성..." -ForegroundColor Blue
    New-Item -ItemType Directory -Path $SkillsDir -Force | Out-Null
}

if (-not (Test-Path $AgentsDir)) {
    Write-Host "📁 .claude\agents 디렉토리 생성..." -ForegroundColor Blue
    New-Item -ItemType Directory -Path $AgentsDir -Force | Out-Null
}

# 백업 (기존 파일 보존)
if ((Get-ChildItem $SkillsDir -ErrorAction SilentlyContinue).Count -gt 0) {
    $BackupDir = "$env:USERPROFILE\.claude-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Write-Host "💾 기존 스킬 백업 중... ($BackupDir)" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path "$BackupDir\skills" -Force | Out-Null
    Copy-Item "$SkillsDir\*" "$BackupDir\skills\" -Recurse -ErrorAction SilentlyContinue
    Write-Host "✅ 백업 완료!" -ForegroundColor Green
}

# 스킬 복사
Write-Host ""
Write-Host "📦 스킬 설치 중..." -ForegroundColor Blue

$SkillCount = 0
Get-ChildItem ".\skills\*.md" -ErrorAction SilentlyContinue | ForEach-Object {
    Copy-Item $_.FullName $SkillsDir -Force
    Write-Host "  ✓ $($_.Name)" -ForegroundColor Gray
    $SkillCount++
}

# 에이전트 복사
if (Test-Path ".\agents") {
    $AgentFiles = Get-ChildItem ".\agents" -ErrorAction SilentlyContinue
    if ($AgentFiles.Count -gt 0) {
        Write-Host ""
        Write-Host "🤖 에이전트 설치 중..." -ForegroundColor Blue
        Copy-Item ".\agents\*" $AgentsDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# 설정 파일 복사 (선택)
if (Test-Path ".\configs") {
    Write-Host ""
    $response = Read-Host "설정 파일도 덮어쓸까요? (y/N)"
    if ($response -eq 'y' -or $response -eq 'Y') {
        Write-Host "⚙️  설정 파일 복사 중..." -ForegroundColor Blue
        Copy-Item ".\configs\*.json" $ClaudeDir -Force -ErrorAction SilentlyContinue
    }
}

# 완료
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "✨ 설치 완료!" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host ""
Write-Host "📊 설치 요약:" -ForegroundColor Blue
Write-Host "  • 스킬: $SkillCount개"
Write-Host "  • 위치: $SkillsDir"
if ($BackupDir) {
    Write-Host "  • 백업: $BackupDir"
}
Write-Host ""
Write-Host "🎯 사용법:" -ForegroundColor Yellow
Write-Host "  /auto `"요청`"           - Intelligent Orchestrator 사용"
Write-Host "  /skill-name            - 특정 스킬 실행"
Write-Host ""
Write-Host "📚 문서:" -ForegroundColor Blue
Write-Host "  README.md      - 전체 가이드"
Write-Host "  CATALOG.md     - 스킬 카탈로그"
Write-Host ""
Write-Host "Happy Coding! 🚀" -ForegroundColor Cyan
