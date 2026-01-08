---
name: verify-deployment-skill
description: 배포검증, 상태확인, Git상태, Supabase확인, Vercel배포, 다국어테스트, 헬스체크, 시스템점검, 배포완료확인, 언어전환테스트, 데이터베이스검증을 자동으로 수행하는 스킬
---

# Verify Deployment Skill

This skill checks the deployment status and verifies everything is working correctly.

## What this skill does:

1. **Check Git status** - verify all changes are committed
2. **Check Supabase** - verify translations are in database
3. **Check Vercel** - verify deployment status
4. **Test blog pages** - verify 12 languages are working
5. **Generate health report**

## Usage:

Run this skill after deployment to verify everything is working.

## Steps:

1. Run git status to check uncommitted changes
2. Query Supabase for blog count and translations
3. Check if Vercel deployment is complete
4. Verify blog pages are accessible
5. Test language switching functionality
6. Generate comprehensive health report

## Expected Output:

- Git status: clean (all committed)
- Supabase: 20 blogs × 12 languages = 240 entries
- Vercel: deployment successful
- Blog pages: all 12 languages working
- Health report with all checks passed
