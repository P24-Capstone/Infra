## 개발환경 세팅 순서

### 1. Docker Desktop 설치
https://www.docker.com/products/docker-desktop/

### 2. 이 레포 클론
git clone https://github.com/crewise/crewise-infra.git
cd crewise-infra

### 3. 환경변수 파일 세팅
cp .env.example .env
# .env 파일 열어서 팀장한테 받은 실제 값 채워넣기

### 4. 컨테이너 실행
docker-compose up -d

### 5. 확인
docker ps
# crewise-mysql, crewise-redis 두 개가 보이면 성공