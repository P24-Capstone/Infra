-- ============================================================
-- Crewise DB DDL
-- MySQL 8.0
-- 작성일: 2026-04-29
-- 수정일: 2026-05-15
-- ============================================================

SET FOREIGN_KEY_CHECKS = 0;

-- ============================================================
-- 1. USER (사용자)
-- ============================================================
CREATE TABLE `USER` (
    `USER_ID`    VARCHAR(26)  NOT NULL COMMENT 'ULID 생성(문자열 기반 난수)',
    `USER_EMAIL` VARCHAR(100) NOT NULL,
    `USER_PW`    VARCHAR(64)  NOT NULL COMMENT 'SHA-256 해시',
    `USER_NAME`  VARCHAR(50)  NOT NULL,
    `USER_TEL`   VARCHAR(11)  NOT NULL COMMENT '하이픈 제외로 저장',
    PRIMARY KEY (`USER_ID`),
    UNIQUE KEY `UQ_USER_EMAIL` (`USER_EMAIL`)
) COMMENT = '사용자';

-- ============================================================
-- 2. USER_IMG (사용자 이미지)
-- ============================================================
CREATE TABLE `USER_IMG` (
    `IMG_ID`       BIGINT        NOT NULL AUTO_INCREMENT COMMENT '이미지 순서',
    `USER_ID`      VARCHAR(26)   NOT NULL COMMENT 'FK → USER',
    `IMG_FILE_KEY` VARCHAR(1024) NOT NULL COMMENT 'S3 경로',
    PRIMARY KEY (`IMG_ID`)
) COMMENT = '사용자 이미지 (여러 장 저장 가능)';

-- ============================================================
-- 3. TEAM (모임)
-- ============================================================
CREATE TABLE `TEAM` (
    `TEAM_ID`         VARCHAR(10)  NOT NULL  COMMENT '모임장 생성 난수 (URL 관리용)',
    `TEAM_NAME`       VARCHAR(50)  NOT NULL,
    `TEAM_IMG`        VARCHAR(255) NULL,
    `TEAM_INFO`       TEXT         NULL,
    `TEAM_CATEGORY`   VARCHAR(50)  NOT NULL,
    `CURRENT_MEMBERS` TINYINT      NOT NULL  DEFAULT 1,
    `MAX_MEMBERS`     TINYINT      NOT NULL  DEFAULT 15 COMMENT 'MAX 15',
    `CODE`            VARCHAR(10)  NULL      COMMENT '초대코드',
    PRIMARY KEY (`TEAM_ID`)
) COMMENT = '모임';

-- ============================================================
-- 4. MEMBER (모임원)
-- ============================================================
CREATE TABLE `MEMBER` (
    `MEM_ID`    VARCHAR(26) NOT NULL COMMENT 'ULID 생성(문자열 기반 난수)',
    `MEM_NIC`   VARCHAR(20) NOT NULL COMMENT '모임 내 닉네임',
    `MEM_ROLE`  CHAR(1)     NOT NULL DEFAULT 'M' COMMENT 'L(모임장)/S(서기)/M(일반멤버)',
    `MEM_STATE` CHAR(1)     NOT NULL DEFAULT 'W' COMMENT 'W(대기), A(승인), R(거절)',
    `REG_DTM`   VARCHAR(19) NOT NULL COMMENT '가입일시 포맷: YYYY-MM-DD HH:mm:ss',
    `PROC_DTM`  VARCHAR(19) NULL     COMMENT '처리일시 포맷: YYYY-MM-DD HH:mm:ss',
    `USER_ID`   VARCHAR(26) NOT NULL COMMENT 'FK → USER',
    `TEAM_ID`   VARCHAR(10) NOT NULL COMMENT 'FK → TEAM',
    `USER_IMG_ID`   BIGINT  NOT NULL COMMENT 'FK → USER_IMG',
    PRIMARY KEY (`MEM_ID`)
) COMMENT = '모임원';

-- ============================================================
-- 5. EVENTS (일정)
-- ============================================================
CREATE TABLE `EVENTS` (
    `EVT_ID`      BIGINT      NOT NULL AUTO_INCREMENT,
    `EVT_TITLE`   VARCHAR(50) NOT NULL,
    `EVT_CONTENT` TEXT        NOT NULL,
    `EVT_START_DT` VARCHAR(10) NOT NULL COMMENT '포맷: YYYY-MM-DD',
    `EVT_END_DT`   VARCHAR(10) NOT NULL COMMENT '포맷: YYYY-MM-DD',
    `EVT_REG_DTM`  VARCHAR(19) NOT NULL COMMENT '포맷: YYYY-MM-DD HH:mm:ss',
    `TEAM_ID`      VARCHAR(10) NOT NULL COMMENT 'FK → TEAM',
    PRIMARY KEY (`EVT_ID`)
) COMMENT = '일정';

-- ============================================================
-- 6. NOTICES (공지사항)
-- ============================================================
CREATE TABLE `NOTICES` (
    `NOTI_ID`      BIGINT      NOT NULL AUTO_INCREMENT,
    `NOTI_TITLE`   VARCHAR(50) NOT NULL,
    `NOTI_CONTENT` TEXT        NULL,
    `NOTI_FIX`     CHAR(1)     NOT NULL DEFAULT 'N' COMMENT 'N(기본)/Y(고정)',
    `REG_DTM`      VARCHAR(19) NOT NULL COMMENT '포맷: YYYY-MM-DD HH:mm:ss',
    `MOD_DTM`      VARCHAR(19) NULL     COMMENT '수정일시 포맷: YYYY-MM-DD HH:mm:ss',
    `TEAM_ID`      VARCHAR(10) NOT NULL COMMENT 'FK → TEAM',
    PRIMARY KEY (`NOTI_ID`)
) COMMENT = '공지사항';

-- ============================================================
-- 7. VOTE (투표)
-- ============================================================
CREATE TABLE `VOTE` (
    `VOTE_ID`      BIGINT      NOT NULL AUTO_INCREMENT,
    `VOTE_TITLE`   VARCHAR(50) NOT NULL,
    `VOTE_CONTENT` TEXT        NOT NULL,
    `VOTE_START_DT` VARCHAR(10) NOT NULL COMMENT '포맷: YYYY-MM-DD',
    `VOTE_END_DT`   VARCHAR(10) NOT NULL COMMENT '포맷: YYYY-MM-DD',
    `VOTE_TYPE`     CHAR(1)     NOT NULL DEFAULT 'N' COMMENT 'Y(익명)/N(공개)',
    `VOTE_RULE`     CHAR(1)     NOT NULL DEFAULT 'V' COMMENT 'R(팀장 검토)/V(재투표)',
    `VOTE_MULTI`    CHAR(1)     NOT NULL DEFAULT 'N' COMMENT 'Y(다중)/N(단일)',
    `VOTE_REG_DTM`  VARCHAR(19) NOT NULL COMMENT '포맷: YYYY-MM-DD HH:mm:ss',
    `TEAM_ID`       VARCHAR(10) NOT NULL COMMENT 'FK → TEAM',
    PRIMARY KEY (`VOTE_ID`)
) COMMENT = '투표';

-- ============================================================
-- 8. VOTE_OPTION (투표 선택지)
-- ============================================================
CREATE TABLE `VOTE_OPTION` (
    `OPT_SN`      BIGINT       NOT NULL AUTO_INCREMENT COMMENT '선택지 순서 의미 있어 SN 유지',
    `OPT_CONTENT` VARCHAR(100) NOT NULL,
    `VOTE_ID`     BIGINT       NOT NULL COMMENT 'FK → VOTE',
    PRIMARY KEY (`OPT_SN`)
) COMMENT = '투표 선택지';

-- ============================================================
-- 9. VOTE_HISTORY (투표 참여내역)
-- ============================================================
CREATE TABLE `VOTE_HISTORY` (
    `VOTE_ID` BIGINT      NOT NULL COMMENT 'FK → VOTE',
    `MEM_ID`  VARCHAR(26) NOT NULL COMMENT 'FK → MEMBER',
    `OPT_SN`  BIGINT      NOT NULL COMMENT 'FK → VOTE_OPTION',
    PRIMARY KEY (`VOTE_ID`, `MEM_ID`, `OPT_SN`) COMMENT '복합키: 중복투표 방지 (다중투표 허용)'
) COMMENT = '투표 참여내역';

-- ============================================================
-- 10. MEETING_RECORD (AI 회의록)
-- ============================================================
CREATE TABLE `MEETING_RECORD` (
    `MEETING_ID`    BIGINT      NOT NULL AUTO_INCREMENT,
    `MEETING_TITLE` TEXT        NOT NULL COMMENT '트랜잭션 처리 (AI 자동생성)',
    `FULL_SCRIPT`  TEXT        NOT NULL COMMENT '트랜잭션 처리 (STT 결과)',
    `AI_SUMMARY`   TEXT        NOT NULL COMMENT '트랜잭션 처리 (AI 요약)',
    `REG_DTM`      VARCHAR(19) NOT NULL COMMENT '포맷: YYYY-MM-DD HH:mm:ss',
    `TEAM_ID`      VARCHAR(10) NOT NULL COMMENT 'FK → TEAM',
    PRIMARY KEY (`MEETING_ID`)
) COMMENT = 'AI 회의록';

-- ============================================================
-- 11. REC_FILE (회의록 음성파일)
-- ============================================================
CREATE TABLE `REC_FILE` (
    `REC_FILE_ID`  BIGINT        NOT NULL AUTO_INCREMENT,
    `MEETING_ID`      BIGINT        NULL     COMMENT 'FK → MEETING_RECORD (트랜잭션 성공 후 연결, NULL 허용)',
    `REC_FILE_KEY` VARCHAR(1024) NOT NULL COMMENT 'S3 경로',
    PRIMARY KEY (`REC_FILE_ID`)
) COMMENT = '회의록 음성파일';

-- ============================================================
-- 12. MISSION (미션)
-- ============================================================
CREATE TABLE `MISSION` (
    `MISSION_ID`      BIGINT       NOT NULL AUTO_INCREMENT,
    `MISSION_TITLE`   VARCHAR(100) NOT NULL,
    `MISSION_CONTENT` TEXT         NOT NULL,
    `MISSION_TYPE`    CHAR(1)      NOT NULL COMMENT 'A(전체)/P(개인)',
    `VERIFY_PROMPT`   TEXT         NOT NULL COMMENT 'AI 인증 조건 프롬프트',
    `MISSION_START_DTM` VARCHAR(19) NOT NULL COMMENT '포맷: YYYY-MM-DD HH:mm:ss',
    `MISSION_END_DTM`   VARCHAR(19) NOT NULL COMMENT '포맷: YYYY-MM-DD HH:mm:ss',
    `TEAM_ID`         VARCHAR(10)  NOT NULL COMMENT 'FK → TEAM',
    PRIMARY KEY (`MISSION_ID`)
) COMMENT = '미션';

-- ============================================================
-- 13. MISSION_VERIFY (미션 인증)
-- ============================================================
CREATE TABLE `MISSION_VERIFY` (
    `VERIFY_ID`      BIGINT      NOT NULL AUTO_INCREMENT,
    `VERIFY_CONTENT` TEXT        NULL     COMMENT '인증 본문 (텍스트)',
    `VERIFY_REG_DTM` VARCHAR(19) NOT NULL COMMENT '제출일시 포맷: YYYY-MM-DD HH:mm:ss',
    `AI_REJECT_YN`   CHAR(1)     NOT NULL DEFAULT 'N' COMMENT 'Y(AI리젝)/N(AI통과)',
    `AI_RESULT`      TEXT        NULL     COMMENT 'AI 판정 결과 및 사유',
    `VERIFY_STATE`   CHAR(1)     NOT NULL DEFAULT 'P'
                     COMMENT 'P(대기)/A(AI승인)/F(강제승인)/R(반려)',
    `MISSION_ID`     BIGINT      NOT NULL COMMENT 'FK → MISSION',
    `MEM_ID`         VARCHAR(26) NOT NULL COMMENT 'FK → MEMBER',
    PRIMARY KEY (`VERIFY_ID`)
) COMMENT = '미션 인증';

-- ============================================================
-- 14. VERIFY_FILE (미션 인증 첨부파일)
-- ============================================================
CREATE TABLE `VERIFY_FILE` (
    `VERIFY_FILE_ID`  BIGINT        NOT NULL AUTO_INCREMENT,
    `VERIFY_FILE_KEY` VARCHAR(1024) NOT NULL COMMENT 'S3 경로',
    `VERIFY_ID`       BIGINT        NOT NULL COMMENT 'FK → MISSION_VERIFY',
    PRIMARY KEY (`VERIFY_FILE_ID`)
) COMMENT = '미션 인증 첨부파일';

-- ============================================================
-- 15. MISSION_FILE (미션 첨부파일)
-- ============================================================
CREATE TABLE `MISSION_FILE` (
    `MISSION_FILE_SN`  BIGINT        NOT NULL AUTO_INCREMENT COMMENT '미션 파일 순서',
    `MISSION_FILE_KEY` VARCHAR(1024) NOT NULL COMMENT 'S3 경로',
    `MISSION_ID`       BIGINT        NOT NULL COMMENT 'FK → MISSION',
    PRIMARY KEY (`MISSION_FILE_SN`)
) COMMENT = '미션 첨부파일';

-- ============================================================
-- 16. NEWS (최근소식)
-- ============================================================
CREATE TABLE `NEWS` (
    `NEWS_ID`      BIGINT       NOT NULL AUTO_INCREMENT,
    `TARGET_TYPE`  CHAR(1)      NOT NULL
                   COMMENT 'M(신규멤버)/I(회의록)/N(공지)/E(일정)/V(투표)/A(미션인증)',
    `TARGET_ID`    BIGINT       NULL
                   COMMENT '클릭 이동 대상 ID (M,A는 NULL 가능)',
    `NEWS_CONTENT` VARCHAR(255) NOT NULL
                   COMMENT '포맷: {닉네임}님이 모임에 가입했어요!',
    `TEAM_ID`      VARCHAR(10)  NOT NULL COMMENT 'FK → TEAM',
) COMMENT = '최근소식';

-- ============================================================
-- 17. COMMENTS (댓글)
-- 신규모임원(M), 미션인증성공(A) 소식에만 달림
-- ============================================================
CREATE TABLE `COMMENTS` (
    `CMT_ID`      BIGINT      NOT NULL AUTO_INCREMENT,
    `CMT_CONTENT` TEXT        NOT NULL,
    `CMT_REG_DTM` VARCHAR(19) NOT NULL COMMENT '포맷: YYYY-MM-DD HH:mm:ss',
    `CMT_MOD_DTM` VARCHAR(19) NULL     COMMENT '수정일시 포맷: YYYY-MM-DD HH:mm:ss',
    `NEWS_ID`     BIGINT      NOT NULL COMMENT 'FK → NEWS',
    `MEM_ID`      VARCHAR(26) NOT NULL COMMENT 'FK → MEMBER',
    PRIMARY KEY (`CMT_ID`)
) COMMENT = '댓글 (신규모임원/미션인증 소식에만 허용)';


-- ============================================================
-- FK 제약조건
-- ============================================================

-- USER_IMG
ALTER TABLE `USER_IMG`
    ADD CONSTRAINT `FK_USER_TO_USER_IMG`
    FOREIGN KEY (`USER_ID`) REFERENCES `USER` (`USER_ID`);

-- MEMBER
ALTER TABLE `MEMBER`
    ADD CONSTRAINT `FK_USER_TO_MEMBER`
    FOREIGN KEY (`USER_ID`) REFERENCES `USER` (`USER_ID`);

ALTER TABLE `MEMBER`
    ADD CONSTRAINT `FK_TEAM_TO_MEMBER`
    FOREIGN KEY (`TEAM_ID`) REFERENCES `TEAM` (`TEAM_ID`);

ALTER TABLE `MEMBER`
    ADD CONSTRAINT `FK_USER_IMG_TO_MEMBER`
    FOREIGN KEY (`USER_IMG_ID`) REFERENCES `USER_IMG` (`IMG_ID`);

-- EVENTS
ALTER TABLE `EVENTS`
    ADD CONSTRAINT `FK_TEAM_TO_EVENTS`
    FOREIGN KEY (`TEAM_ID`) REFERENCES `TEAM` (`TEAM_ID`);

-- NOTICES
ALTER TABLE `NOTICES`
    ADD CONSTRAINT `FK_TEAM_TO_NOTICES`
    FOREIGN KEY (`TEAM_ID`) REFERENCES `TEAM` (`TEAM_ID`);

-- VOTE
ALTER TABLE `VOTE`
    ADD CONSTRAINT `FK_TEAM_TO_VOTE`
    FOREIGN KEY (`TEAM_ID`) REFERENCES `TEAM` (`TEAM_ID`);

-- VOTE_OPTION
ALTER TABLE `VOTE_OPTION`
    ADD CONSTRAINT `FK_VOTE_TO_VOTE_OPTION`
    FOREIGN KEY (`VOTE_ID`) REFERENCES `VOTE` (`VOTE_ID`);

-- VOTE_HISTORY
ALTER TABLE `VOTE_HISTORY`
    ADD CONSTRAINT `FK_VOTE_TO_VOTE_HISTORY`
    FOREIGN KEY (`VOTE_ID`) REFERENCES `VOTE` (`VOTE_ID`);

ALTER TABLE `VOTE_HISTORY`
    ADD CONSTRAINT `FK_MEMBER_TO_VOTE_HISTORY`
    FOREIGN KEY (`MEM_ID`) REFERENCES `MEMBER` (`MEM_ID`);

ALTER TABLE `VOTE_HISTORY`
    ADD CONSTRAINT `FK_OPT_TO_VOTE_HISTORY`
    FOREIGN KEY (`OPT_SN`) REFERENCES `VOTE_OPTION` (`OPT_SN`);

-- MEETING_RECORD
ALTER TABLE `MEETING_RECORD`
    ADD CONSTRAINT `FK_TEAM_TO_MEETING_RECORD`
    FOREIGN KEY (`TEAM_ID`) REFERENCES `TEAM` (`TEAM_ID`);

-- REC_FILE
ALTER TABLE `REC_FILE`
    ADD CONSTRAINT `FK_MEETING_RECORD_TO_REC_FILE`
    FOREIGN KEY (`MEETING_ID`) REFERENCES `MEETING_RECORD` (`MEETING_ID`);

-- MISSION
ALTER TABLE `MISSION`
    ADD CONSTRAINT `FK_TEAM_TO_MISSION`
    FOREIGN KEY (`TEAM_ID`) REFERENCES `TEAM` (`TEAM_ID`);

-- MISSION_FILE
ALTER TABLE `MISSION_FILE`
    ADD CONSTRAINT `FK_MISSION_TO_MISSION_FILE`
    FOREIGN KEY (`MISSION_ID`) REFERENCES `MISSION` (`MISSION_ID`);

-- MISSION_VERIFY
ALTER TABLE `MISSION_VERIFY`
    ADD CONSTRAINT `FK_MISSION_TO_VERIFY`
    FOREIGN KEY (`MISSION_ID`) REFERENCES `MISSION` (`MISSION_ID`);

ALTER TABLE `MISSION_VERIFY`
    ADD CONSTRAINT `FK_MEMBER_TO_VERIFY`
    FOREIGN KEY (`MEM_ID`) REFERENCES `MEMBER` (`MEM_ID`);

-- VERIFY_FILE
ALTER TABLE `VERIFY_FILE`
    ADD CONSTRAINT `FK_VERIFY_TO_VERIFY_FILE`
    FOREIGN KEY (`VERIFY_ID`) REFERENCES `MISSION_VERIFY` (`VERIFY_ID`);

-- NEWS
ALTER TABLE `NEWS`
    ADD CONSTRAINT `FK_TEAM_TO_NEWS`
    FOREIGN KEY (`TEAM_ID`) REFERENCES `TEAM` (`TEAM_ID`);

-- COMMENTS
ALTER TABLE `COMMENTS`
    ADD CONSTRAINT `FK_NEWS_TO_COMMENTS`
    FOREIGN KEY (`NEWS_ID`) REFERENCES `NEWS` (`NEWS_ID`);

ALTER TABLE `COMMENTS`
    ADD CONSTRAINT `FK_MEMBER_TO_COMMENTS`
    FOREIGN KEY (`MEM_ID`) REFERENCES `MEMBER` (`MEM_ID`);


SET FOREIGN_KEY_CHECKS = 1;