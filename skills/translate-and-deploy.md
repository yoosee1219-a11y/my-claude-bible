---
name: translate-and-deploy-skill
description: 블로그번역, 다국어번역, 자동배포, Git커밋, GitHub푸시, Vercel배포, 번역검증, 8개언어, 워크플로우자동화, 번역통계, 배포상태확인을 통합 지원하는 스킬
---

# Translate and Deploy Skill

This skill automates the entire blog translation and deployment workflow.

## What this skill does:

1. **Translate all blogs** to 8 languages (VI, TH, UZ, NE, MN, ID, MY, RU)
2. **Verify translations** - check for missing content
3. **Git commit** with detailed version message
4. **Git push** to GitHub
5. **Verify Vercel deployment**
6. **Generate completion report**

## Usage:

Run this skill when you have new blog content that needs to be translated and deployed.

## Steps:

1. Execute translation script with retry logic
2. Run check-missing.js to verify all translations
3. Stage all changes to Git
4. Create detailed commit message
5. Push to GitHub repository
6. Check Vercel deployment status
7. Generate final report with statistics

## Expected Output:

- All 20 blogs translated to 8 languages
- Git commit with version tracking
- GitHub repository updated
- Vercel auto-deployment triggered
- Completion report with translation statistics
