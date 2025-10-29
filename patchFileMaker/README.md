# CloudESM Patch Creator - 사용 가이드

Windows용 Git 커밋 기반 패치 파일 생성 도구입니다.

## 📋 기능

- ✅ 수정된 파일로 패치 생성
- ✅ Git 커밋 히스토리에서 선택하여 패치 생성
- ✅ 여러 커밋을 통합하여 하나의 패치 생성
- ✅ 커밋 검색 기능 (키워드로 검색)
- ✅ 페이징 지원 (10개씩 탐색)
- ✅ Java .class 파일 자동 포함
- ✅ Grunt 빌드 결과물 자동 포함
- ✅ 한글 완벽 지원

---

## 🔧 설치 방법

### 자동 설치 (권장) ⚡

**1단계: 파일 배치**
```
C:\Users\{사용자이름}\Scripts\
  ├── create_patch.ps1   👈 패치 생성 스크립트
  └── install.ps1        👈 자동 설치 스크립트
```

**2단계: 자동 설치 실행**
```powershell
cd C:\Users\{사용자이름}\Scripts
.\install.ps1
```

**3단계: PowerShell 재시작**

**완료! 이제 어디서든 `patch` 명령어로 실행 가능합니다! 🎉**

---

### 수동 설치 (고급 사용자)

<details>
<summary>클릭하여 수동 설치 방법 보기</summary>

#### 1. PowerShell 실행 정책 설정 (최초 1회만)

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### 2. 스크립트 파일 배치

```
C:\Users\{사용자이름}\Scripts\
  └── create_patch.ps1
```

#### 3. PowerShell 프로파일 수정

```powershell
# 프로파일 열기
notepad $PROFILE

# 다음 내용 추가
function Create-Patch {
    & "C:\Users\$env:USERNAME\Scripts\create_patch.ps1" @args
}
Set-Alias -Name patch -Value Create-Patch
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
```

#### 4. PowerShell 재시작 또는 프로파일 리로드

```powershell
. $PROFILE
```

</details>

---

## 🚀 사용 방법

### 방법 1: 수정된 파일로 패치 생성 (기본)

```powershell
# 1. 프로젝트 폴더로 이동
cd "C:\work\eyeCloudXOAR V4\web"

# 2. 패치 생성 실행
patch

# 3. 모드 선택
Mode (1/2): 1   # 1 입력 (현재 수정된 파일)

# 4. 패치 정보 입력
Patch Name: ISSUE-123
Description: 버그 수정
```

### 방법 2: 커밋 선택으로 패치 생성

```powershell
# 1. 프로젝트 폴더로 이동
cd "C:\work\eyeCloudXOAR V4\web"

# 2. 패치 생성 실행
patch

# 3. 모드 선택
Mode (1/2): 2   # 2 입력 (커밋 선택)

# 4. 커밋 리스트 확인
===============================================
  Commits 1-10
===============================================

  [1] abc1234 - 버그 수정
  [2] def5678 - 기능 추가
  [3] ghi9012 - 성능 개선
  ...

# 5. 명령어 사용
Selection: 1,3,5        # 1, 3, 5번 커밋 선택
# 또는
Selection: 1-3          # 1~3번 커밋 선택
# 또는
Selection: n            # 다음 10개 커밋 보기
# 또는
Selection: s            # 검색 모드
```

---

## 📖 명령어 가이드

### 커밋 선택 모드에서 사용 가능한 명령어

| 명령어 | 단축키 | 설명 | 예시 |
|--------|--------|------|------|
| **선택** | - | 커밋 번호로 선택 | `1,3,5` 또는 `1-3` |
| **next** | `n` | 다음 10개 커밋 보기 | `n` |
| **prev** | `p` | 이전 10개 커밋 보기 | `p` |
| **search** | `s` | 커밋 메시지 검색 | `s` → `버그` |
| **clear** | `c` | 검색 모드 해제 | `c` |
| **Enter** | - | 취소 | (빈 입력) |

### 선택 방법 예시

```powershell
# 개별 선택
Selection: 1,3,5,7
→ 1번, 3번, 5번, 7번 커밋 선택

# 범위 선택
Selection: 1-5
→ 1, 2, 3, 4, 5번 커밋 선택

# 혼합 선택
Selection: 1,3-5,8,10-12
→ 1, 3, 4, 5, 8, 10, 11, 12번 커밋 선택
```

---

## 🔍 검색 사용 예시

### 시나리오 1: 키워드로 검색
```powershell
Selection: s
Enter search keyword: 버그수정

# '버그수정'이 포함된 커밋만 표시
===============================================
  Search Results: '버그수정' (Commits 1-3)
===============================================

  [1] abc1234 - 버그수정: 로그인 오류
  [2] def5678 - 버그수정: 화면 깨짐
  [3] ghi9012 - 버그수정: API 에러

Selection: 1,2   # 검색 결과에서 선택
```

### 시나리오 2: 검색 후 더 많은 결과 보기
```powershell
Selection: s
Enter search keyword: dashboard

# 첫 10개 검색 결과
Selection: n     # 다음 10개 검색 결과
Selection: n     # 또 다음 10개
Selection: 1-3   # 선택
```

### 시나리오 3: 검색 해제
```powershell
# 검색 모드에서
Selection: c     # 검색 해제
# → 전체 커밋 표시로 복귀
```

---

## 📦 패치 파일 위치

생성된 패치 파일은 자동으로 다운로드 폴더에 저장됩니다:

```
C:\Users\{사용자이름}\Downloads\
  ├── UEBA_Patch_{패치이름}\      # 폴더
  │   ├── PATCH_README.txt
  │   └── www\
  │       └── ROOT\
  │           ├── WEB-INF\
  │           └── resources\
  └── patch_{패치이름}.zip         # ZIP 파일
```

---

## 🛠️ 전제 조건

### 필수 소프트웨어

1. **Git**: Git Bash 또는 Git for Windows 설치 필요
2. **PowerShell**: Windows 10/11에 기본 포함
3. **Maven**: Java 프로젝트 빌드용 (선택사항)
4. **Node.js & Grunt**: Frontend 빌드용 (선택사항)

### 프로젝트 빌드 상태

패치 생성 전에 프로젝트를 빌드해야 합니다:

```powershell
# Java 빌드 (필수)
mvn clean compile

# Frontend 빌드 (선택사항)
cd src/main/frontend
grunt
```

---

## ⚙️ 설정

### 제외 파일 설정

스크립트 파일을 열고 `$excludeFiles` 배열을 수정:

```powershell
$excludeFiles = @(
    ".classpath",
    ".project",
    "AppConfig.xml",
    "jdbc-mysql.properties",
    "web.xml",
    "commons-util-2.5.jar"
    # 여기에 제외할 파일 추가
    "test.properties",
    "debug.log"
)
```

### 한글 인코딩 설정 (자동)

스크립트가 자동으로 UTF-8 인코딩을 설정합니다.
만약 문제가 있다면 PowerShell 프로파일에 추가:

```powershell
# 프로파일 열기
notepad $PROFILE

# 다음 내용 추가
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null
```

---

## 🎯 고급 사용법

### 파라미터로 직접 실행

```powershell
# 기본 모드로 바로 실행
patch -PatchName "ISSUE-123" -Description "버그 수정"

# 커밋 선택 모드로 바로 실행
patch -UseCommits

# 모든 파라미터 지정
patch -PatchName "ISSUE-123" -Description "버그 수정" -UseCommits
```

### 배치 파일 만들기 (옵션)

특정 프로젝트 전용 배치 파일:

**create_patch.bat**
```batch
@echo off
cd /d "C:\work\eyeCloudXOAR V4\web"
powershell -Command "patch"
pause
```

더블클릭으로 실행 가능!

---

## ❓ 문제 해결

### 1. "스크립트 실행이 금지되어 있습니다"

**해결방법:**
```powershell
# 관리자 권한 PowerShell에서
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 2. "git을 인식할 수 없습니다"

**해결방법:**
- Git for Windows 설치: https://git-scm.com/download/win
- 설치 후 PowerShell 재시작

### 3. 한글이 깨져 보임

**해결방법:**
```powershell
# PowerShell에서
chcp 65001

# 또는 PowerShell Core 사용
pwsh -File create_patch.ps1
```

### 4. ".class 파일을 찾을 수 없습니다"

**해결방법:**
```powershell
# Maven 빌드 실행
mvn clean compile
```

### 5. "JS 파일을 찾을 수 없습니다"

**해결방법:**
```powershell
# Frontend 빌드 실행
cd src/main/frontend
grunt
```

---

## 📝 패치 적용 방법

생성된 패치를 서버에 적용:

### Windows
```batch
# 1. Tomcat 중지
net stop Tomcat8

# 2. 백업
xcopy C:\Tomcat8\webapps\ROOT C:\Backup\ROOT_%date% /E /I

# 3. 패치 적용
xcopy C:\Downloads\UEBA_Patch_xxx\www\ROOT C:\Tomcat8\webapps\ROOT /E /Y

# 4. Tomcat 시작
net start Tomcat8
```

### Linux
```bash
# 1. Tomcat 중지
systemctl stop tomcat8

# 2. 백업
cp -r /opt/tomcat8/webapps/ROOT /backup/ROOT_$(date +%Y%m%d)

# 3. 패치 적용
cp -r /tmp/UEBA_Patch_xxx/www/ROOT/* /opt/tomcat8/webapps/ROOT/

# 4. Tomcat 시작
systemctl start tomcat8
```

---

## 📞 지원

문제가 발생하거나 기능 요청이 있으면:
- 개발팀에 문의
- 또는 스크립트를 수정하여 사용 (오픈소스)

---

## 📄 라이선스

내부 사용 목적으로 자유롭게 수정 및 배포 가능합니다.

---

## 📌 버전 정보

- **버전**: 2.0
- **최종 업데이트**: 2025-10-29
- **호환성**: Windows 10/11, PowerShell 5.1+

