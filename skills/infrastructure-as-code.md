# Infrastructure as Code (Terraform + Pulumi)

> 클릭 한 번에 인프라를 배포하고, 코드로 모든 것을 관리하는 IaC 완전 가이드 (2026년 최신)

## 목차

1. [IaC가 왜 필요한가?](#iac가-왜-필요한가)
2. [Terraform vs Pulumi 비교](#terraform-vs-pulumi-비교)
3. [Terraform 시작하기](#terraform-시작하기)
4. [Pulumi 시작하기](#pulumi-시작하기)
5. [실전 사례](#실전-사례)

---

## IaC가 왜 필요한가?

### 수동 인프라 관리의 문제점

**시간 낭비** ⏰
```
스타트업 A의 현실:
- AWS 콘솔에서 수동 설정: EC2, RDS, S3, CloudFront 등
- 개발/스테이징/프로덕션 환경 각각 설정: 하루 소요
- 실수로 인한 재작업: 주당 2-3회
- 연간 손실: 52주 * 3시간 = 156시간 ($7,800)
```

**환경 불일치** 😞
```
문제:
- 개발 환경: PostgreSQL 14
- 프로덕션 환경: PostgreSQL 15 (담당자 실수)
- 결과: 쿼리 동작 차이로 프로덕션 장애
- 장애 대응 비용: 6시간 * $200/시간 = $1,200
```

**재현 불가능** 🐌
```
6개월 후 새 환경 구축 시:
- 기존 설정 기억 안 남
- AWS 콘솔 클릭 이력 없음
- 문서 구버전 (50% 정확도)
- 새 환경 구축: 3일 소요 (기존 1일)
```

### IaC의 이점

**버전 관리** 🚀
```hcl
# terraform/main.tf (Git으로 관리)
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.medium"  # 이전: t2.micro → 변경 이력 추적
}
```
- 모든 변경 이력 Git에 저장
- 롤백 가능 (`git checkout previous-commit`)
- 리뷰 가능 (Pull Request)

**재현 가능** ✅
```bash
terraform apply  # 1분 내 동일한 환경 재생성
```
- 개발/스테이징/프로덕션 환경 **100% 동일**
- 신규 팀원도 `terraform apply` 한 번으로 환경 구축

**비용 절감** 💰
- 인프라 설정 시간: 하루 → 10분 (94% 절감)
- 장애 대응 속도: 6시간 → 30분 (91% 단축)
- 연간 절감: $20,000+ (5인 스타트업 기준)

---

## Terraform vs Pulumi 비교

| 항목 | Terraform | Pulumi |
|------|-----------|--------|
| 언어 | HCL (전용 언어) | TypeScript, Python, Go, C# 등 |
| Provider 수 | 200+ | 180+ |
| 학습 곡선 | 중간 (새 언어 학습 필요) | 낮음 (기존 언어 사용) |
| 상태 관리 | 로컬 파일 또는 S3 | Pulumi Cloud (무료/유료) |
| 모듈 생태계 | 매우 풍부 | 성장 중 |
| 기업 지원 | 매우 강함 | 강함 |
| 가격 | 오픈소스 무료 | 오픈소스 무료 + Cloud 유료 |
| 최적 사용처 | Ops 팀, 표준화 중시 | 개발자 팀, 복잡한 로직 |

### 선택 가이드

**Terraform을 선택하세요:**
- ✅ 팀이 인프라/Ops 중심
- ✅ 200+ Provider 생태계 활용 필요
- ✅ Terraform Registry 모듈 재사용 중시
- ✅ 기업 표준화 및 컴플라이언스 중요

**Pulumi를 선택하세요:**
- ✅ 팀이 개발자 중심 (TypeScript, Python 사용)
- ✅ 복잡한 조건문, 반복문이 필요한 인프라
- ✅ 타입 안정성 및 IDE 자동완성 선호
- ✅ 빠른 프로토타이핑 필요

---

## Terraform 시작하기

### 설치 (1분)

```bash
# macOS
brew install terraform

# Windows
choco install terraform

# Linux
wget https://releases.hashicorp.com/terraform/1.7.0/terraform_1.7.0_linux_amd64.zip
unzip terraform_1.7.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# 설치 확인
terraform version
```

### AWS 기본 예제 (EC2 + RDS)

```hcl
# terraform/main.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"  # 서울 리전
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main-vpc"
  }
}

# Subnet
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "public-subnet"
  }
}

# Security Group
resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "Allow HTTP/HTTPS traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]

  tags = {
    Name = "web-server"
  }
}

# RDS PostgreSQL
resource "aws_db_instance" "postgres" {
  identifier        = "my-app-db"
  engine            = "postgres"
  engine_version    = "15.4"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name  = "myapp"
  username = var.db_username
  password = var.db_password

  skip_final_snapshot = true
}

# Output
output "web_server_ip" {
  value = aws_instance.web.public_ip
}

output "db_endpoint" {
  value = aws_db_instance.postgres.endpoint
}
```

```hcl
# terraform/variables.tf
variable "db_username" {
  description = "Database username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}
```

```bash
# terraform.tfvars (절대 Git에 커밋하지 말 것!)
db_username = "admin"
db_password = "super-secret-password"
```

### 실행

```bash
# 1. 초기화 (Provider 다운로드)
terraform init

# 2. 계획 확인 (Dry-run)
terraform plan

# 3. 적용
terraform apply

# 4. 삭제 (모든 리소스 제거)
terraform destroy
```

### Vercel + Supabase 배포 예제

```hcl
# terraform/vercel.tf
terraform {
  required_providers {
    vercel = {
      source  = "vercel/vercel"
      version = "~> 1.0"
    }
    supabase = {
      source  = "supabase/supabase"
      version = "~> 1.0"
    }
  }
}

provider "vercel" {
  api_token = var.vercel_api_token
}

provider "supabase" {
  access_token = var.supabase_access_token
}

# Vercel Project
resource "vercel_project" "my_app" {
  name      = "my-app"
  framework = "nextjs"

  git_repository = {
    type = "github"
    repo = "username/my-app"
  }
}

# Supabase Project
resource "supabase_project" "main" {
  organization_id = var.supabase_org_id
  name            = "my-app-db"
  database_password = var.supabase_db_password
  region          = "ap-northeast-1"

  settings = {
    auth = {
      enable_signup = true
    }
  }
}

# Vercel Environment Variables
resource "vercel_project_environment_variable" "supabase_url" {
  project_id = vercel_project.my_app.id
  key        = "NEXT_PUBLIC_SUPABASE_URL"
  value      = supabase_project.main.url
  target     = ["production", "preview"]
}

resource "vercel_project_environment_variable" "supabase_anon_key" {
  project_id = vercel_project.my_app.id
  key        = "NEXT_PUBLIC_SUPABASE_ANON_KEY"
  value      = supabase_project.main.anon_key
  target     = ["production", "preview"]
}
```

---

## Pulumi 시작하기

### 설치

```bash
# macOS/Linux
curl -fsSL https://get.pulumi.com | sh

# Windows
choco install pulumi

# 확인
pulumi version
```

### AWS 예제 (TypeScript)

```bash
# 새 프로젝트 생성
mkdir pulumi-aws-example && cd pulumi-aws-example
pulumi new aws-typescript
```

```typescript
// index.ts
import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";

// VPC
const vpc = new aws.ec2.Vpc("main", {
  cidrBlock: "10.0.0.0/16",
  tags: { Name: "main-vpc" },
});

// Subnet
const subnet = new aws.ec2.Subnet("public", {
  vpcId: vpc.id,
  cidrBlock: "10.0.1.0/24",
  tags: { Name: "public-subnet" },
});

// Security Group
const sg = new aws.ec2.SecurityGroup("web", {
  vpcId: vpc.id,
  description: "Allow HTTP/HTTPS",
  ingress: [
    { protocol: "tcp", fromPort: 80, toPort: 80, cidrBlocks: ["0.0.0.0/0"] },
    { protocol: "tcp", fromPort: 443, toPort: 443, cidrBlocks: ["0.0.0.0/0"] },
  ],
  egress: [
    { protocol: "-1", fromPort: 0, toPort: 0, cidrBlocks: ["0.0.0.0/0"] },
  ],
});

// EC2
const ami = aws.ec2.getAmi({
  mostRecent: true,
  owners: ["amazon"],
  filters: [{ name: "name", values: ["amzn2-ami-hvm-*"] }],
});

const instance = new aws.ec2.Instance("web", {
  instanceType: "t3.medium",
  ami: ami.then((a) => a.id),
  subnetId: subnet.id,
  vpcSecurityGroupIds: [sg.id],
  tags: { Name: "web-server" },
});

// RDS
const db = new aws.rds.Instance("postgres", {
  identifier: "my-app-db",
  engine: "postgres",
  engineVersion: "15.4",
  instanceClass: "db.t3.micro",
  allocatedStorage: 20,
  dbName: "myapp",
  username: "admin",
  password: new pulumi.Config().requireSecret("dbPassword"),
  skipFinalSnapshot: true,
});

// Outputs
export const webServerIp = instance.publicIp;
export const dbEndpoint = db.endpoint;
```

### Pulumi Stack 관리 (환경별)

```bash
# Development stack
pulumi stack init dev
pulumi config set aws:region ap-northeast-2
pulumi config set --secret dbPassword dev-password
pulumi up

# Production stack
pulumi stack init prod
pulumi config set aws:region ap-northeast-2
pulumi config set --secret dbPassword prod-password-strong
pulumi up

# Stack 전환
pulumi stack select dev
pulumi stack select prod
```

### Pulumi의 강력한 기능: 조건문 & 반복문

```typescript
// 복잡한 로직 (Terraform보다 쉬움)
const config = new pulumi.Config();
const env = config.require("environment");

// 환경별 인스턴스 타입
const instanceType = env === "prod" ? "t3.large" : "t3.micro";

// 여러 개의 서버 생성 (반복문)
const servers = [];
for (let i = 0; i < 3; i++) {
  servers.push(
    new aws.ec2.Instance(`web-${i}`, {
      instanceType,
      ami: ami.then((a) => a.id),
      tags: { Name: `web-server-${i}` },
    })
  );
}

// 조건부 리소스 생성
if (env === "prod") {
  new aws.cloudwatch.MetricAlarm("high-cpu", {
    // 프로덕션에서만 알람 생성
  });
}
```

---

## 실전 사례

### 사례 1: 스타트업 (5명 팀)

**Before (AWS 콘솔 수동 관리)**
```
환경 구축:
- 개발: 4시간
- 스테이징: 4시간 (복사 + 수정)
- 프로덕션: 6시간 (신중하게)
- 총: 14시간

문제점:
- 환경 불일치로 버그: 월 2회
- 프로덕션 장애 대응: 평균 4시간
```

**After (Terraform)**
```hcl
# terraform/environments/dev.tfvars
environment = "dev"
instance_type = "t3.micro"

# terraform/environments/prod.tfvars
environment = "prod"
instance_type = "t3.large"

# 실행
terraform apply -var-file=environments/dev.tfvars   # 5분
terraform apply -var-file=environments/prod.tfvars  # 5분

환경 구축: 14시간 → 10분 (99% 절감)
환경 불일치 버그: 0회
장애 대응: 4시간 → 30분 (롤백 즉시)
```

**ROI:**
```
연간 절감 시간:
- 인프라 설정: 50시간 (14시간 * 4회/년 - 40분)
- 버그 대응: 96시간 (4시간 * 24건)
- 총: 146시간

인건비 환산: 146시간 * $50/시간 = $7,300/년
초기 투자: 16시간 학습 ($800)
1년 ROI: 812%
```

### 사례 2: SaaS 기업 (50명 팀)

**Multi-cloud 인프라 (AWS + GCP)**
```python
# Pulumi (Python)
import pulumi
import pulumi_aws as aws
import pulumi_gcp as gcp

# AWS에 웹 서버
web = aws.ec2.Instance("web",
    instance_type="t3.large",
    ami="ami-xxx"
)

# GCP에 데이터 분석
bigquery = gcp.bigquery.Dataset("analytics",
    dataset_id="user_analytics",
    location="US"
)

# AWS S3 → GCP BigQuery 데이터 파이프라인
# (Python 코드로 복잡한 로직 구현 가능)
```

**성과:**
- 인프라 프로비저닝: 2일 → 1시간 (95% 단축)
- 멀티클라우드 관리: 1개 코드베이스
- 비용 최적화: AWS + GCP 조합으로 30% 절감

---

## 체크리스트

### Terraform 시작 전
- [ ] AWS/GCP 계정 준비 및 IAM 사용자 생성
- [ ] Terraform CLI 설치
- [ ] `.gitignore`에 `*.tfstate`, `*.tfvars` 추가
- [ ] State 백엔드 설정 (S3 권장)

### Pulumi 시작 전
- [ ] Pulumi CLI 설치
- [ ] Pulumi Cloud 계정 생성 (무료)
- [ ] 선호 언어 선택 (TypeScript, Python 등)
- [ ] IDE에 Pulumi 확장 설치

### 공통 보안
- [ ] 민감한 정보는 변수로 분리 (`sensitive = true`)
- [ ] State 파일 암호화
- [ ] IAM 최소 권한 원칙 적용
- [ ] MFA 활성화

---

## 참고 자료

### Terraform
- [HashiCorp Terraform AWS Tutorial](https://developer.hashicorp.com/terraform/tutorials/aws-get-started)
- [AWS Prescriptive Guidance - Terraform](https://docs.aws.amazon.com/prescriptive-guidance/latest/choose-iac-tool/terraform.html)
- [Supabase Terraform Provider](https://supabase.com/docs/guides/deployment/terraform)
- [테라폼으로 시작하는 IaC (한빛미디어)](https://m.hanbit.co.kr/store/books/book_view.html?p_code=B6444230163)

### Pulumi
- [Pulumi vs Terraform Comparison](https://www.pulumi.com/docs/iac/comparisons/terraform/)
- [Pulumi Get Started](https://www.pulumi.com/docs/get-started/)

### 2026 가이드
- [Infrastructure as Code Complete Guide 2026](https://towardsthecloud.com/blog/infrastructure-as-code)
- [Terraform vs Pulumi for Multi-Cloud 2026](https://softwarelogic.co/en/blog/7-key-differences-terraform-vs-pulumi-for-multi-cloud-in-2026)

---

## 마무리

이 가이드를 따라 구현하면:

1. ✅ **시간 절약**: 인프라 설정 **95%+ 단축**
2. ✅ **환경 일관성**: 개발/스테이징/프로덕션 **100% 동일**
3. ✅ **빠른 롤백**: 장애 대응 시간 **90%+ 단축**
4. ✅ **비용 절감**: 연간 **$5,000-$50,000** 절감
5. ✅ **협업 강화**: Git으로 인프라 변경 **리뷰 가능**

Infrastructure as Code, 지금 시작하세요! ☁️
