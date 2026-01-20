# 보안 정책 (Security Policy)

## 🔒 보안 취약점 보고

보안 취약점을 발견하셨나요? 아래 절차를 따라 주세요.

### 보고 방법

**공개 이슈로 보고하지 마세요!** 보안 취약점은 다음 방법으로 비공개로 보고해 주세요:

1. GitHub Security Advisory를 통한 보고
2. 프로젝트 관리자에게 직접 이메일

### 보고 시 포함할 정보

- 취약점에 대한 상세한 설명
- 재현 단계
- 영향 범위 (심각도)
- 가능한 경우 PoC (Proof of Concept)
- 권장 수정 방법 (선택사항)

## 🛡️ 지원되는 버전

| 버전 | 지원 여부 |
| --- | --- |
| latest | ✅ 지원 |
| < latest | ❌ 미지원 |

## ⚠️ 알려진 보안 고려사항

### API 키 관리

**위험:** Datadog API 키가 코드에 하드코딩되거나 Git에 커밋되는 경우

**완화 방법:**
- ✅ `variables.tf`에는 변수 선언만 포함 (default 값 없음)
- ✅ 실제 값은 `terraform.tfvars`에 저장 (Git 제외)
- ✅ `sensitive = true` 플래그로 로그 노출 방지
- ✅ AWS Secrets Manager에 암호화 저장

### Terraform State 파일

**위험:** `.tfstate` 파일에 민감한 정보 포함

**완화 방법:**
- ✅ `.gitignore`에 모든 state 파일 포함
- ✅ S3 백엔드 사용 시 암호화 활성화 권장
- ✅ State 파일 접근 권한 최소화

### IAM 권한

**위험:** 과도한 IAM 권한 부여

**완화 방법:**
- ✅ Lambda 함수에 최소 권한 원칙 적용
- ✅ Datadog Forwarder는 공식 템플릿의 권한 사용
- ✅ 정기적인 IAM 권한 검토

## 🔐 보안 체크리스트

배포 전 확인:

### 코드 수준
- [ ] API 키가 코드에 하드코딩되지 않았는지 확인
- [ ] `variables.tf`에 `default` 값이 없는지 확인
- [ ] 모든 민감한 변수에 `sensitive = true` 설정

### Git 수준
- [ ] `.gitignore`에 `*.tfvars` 포함
- [ ] `.gitignore`에 `*.tfstate*` 포함
- [ ] `terraform.tfvars.example`에 실제 값 미포함
- [ ] Git 히스토리에 민감한 정보 없음

### AWS 수준
- [ ] Security Hub가 활성화되어 있는지 확인
- [ ] CloudWatch Logs 모니터링 설정
- [ ] Lambda 함수 환경 변수 암호화
- [ ] Secrets Manager 접근 권한 최소화

## 📋 보안 모범 사례

### 1. API 키 로테이션

정기적으로 Datadog API 키를 변경하세요 (권장: 분기별)

```bash
# 1. 새 API 키 생성 (Datadog Console)
# 2. terraform.tfvars 업데이트
# 3. Terraform 재배포
terraform apply

# 4. 구 API 키 폐기 (Datadog Console)
```

### 2. 최소 권한 원칙

필요한 최소한의 AWS 권한만 사용:

```hcl
# 예: Lambda 실행 역할
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": "arn:aws:secretsmanager:*:*:secret:datadog_api_key*"
    }
  ]
}
```

### 3. 모니터링 및 감사

- CloudWatch Logs로 Lambda 실행 모니터링
- AWS CloudTrail로 API 호출 추적
- Datadog에서 이상 패턴 감지

### 4. 네트워크 보안

필요시 Lambda를 Private Subnet에 배포:

```hcl
resource "aws_lambda_function" "datadog_forwarder" {
  # ... 기타 설정 ...
  
  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
}
```

## 🚨 사고 대응

### API 키 노출 시

1. **즉시 조치 (5분 이내)**
   - Datadog Console에서 API 키 폐기
   - AWS Secrets Manager 값 업데이트

2. **조사 (1시간 이내)**
   - CloudWatch Logs 확인
   - Datadog API 사용 로그 확인
   - 비정상 활동 탐지

3. **복구 (24시간 이내)**
   - 새 API 키 생성 및 배포
   - Git 히스토리에서 제거 (필요시)
   - 보안 검토 수행

4. **예방 (1주일 이내)**
   - 보안 정책 업데이트
   - 팀 교육 실시
   - 자동화된 검사 도구 도입

### Git에 실수로 커밋한 경우

```bash
# 1. 즉시 API 키 폐기
# 2. 커밋 히스토리에서 제거
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch terraform.tfvars" \
  --prune-empty --tag-name-filter cat -- --all

# 3. Force push (리포지토리 재작성)
git push origin --force --all
git push origin --force --tags

# 4. 모든 협업자에게 알림
# 5. 새 API 키로 재배포
```

## 📞 연락처

보안 관련 문의:
- GitHub Issues (일반 문의)
- Security Advisory (보안 취약점)

---

**보안은 모두의 책임입니다. 의심스러운 활동을 발견하면 즉시 보고해 주세요.**
