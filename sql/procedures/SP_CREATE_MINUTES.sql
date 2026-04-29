-- ============================================================
-- Crewise 회의록 트랜잭션 처리
-- MySQL 8.0
-- 작성일: 2026-04-29
-- ============================================================
-- 처리 흐름:
-- [트랜잭션 외부] 녹음 완료 → 음성파일 S3 업로드 → AUDIO_FILE INSERT
-- [트랜잭션 내부] STT → FULL_SCRIPT
--                AI 요약 → AI_SUMMARY
--                AI 제목 → MINUTE_TITLE
--                전체 성공 → MINUTES INSERT + AUDIO_FILE.MINUTE_ID 업데이트
--                하나라도 실패 → 전체 롤백 (AUDIO_FILE은 보존)
-- ============================================================

DELIMITER $$

CREATE PROCEDURE `SP_CREATE_MINUTES` (
    -- 입력 파라미터 (Python AI 서버에서 처리 완료 후 전달)
    IN  p_team_id       VARCHAR(10),   -- 모임 ID
    IN  p_audio_file_id BIGINT,        -- 이미 저장된 AUDIO_FILE ID
    IN  p_minute_title  TEXT,          -- AI 자동 생성 제목
    IN  p_full_script   TEXT,          -- STT 변환 결과
    IN  p_ai_summary    TEXT,          -- AI 요약 결과
    IN  p_reg_dtm       VARCHAR(19),   -- 생성일시 (포맷: YYYY-MM-DD HH:mm:ss)
    OUT p_result_code   INT,           -- 0: 성공, 1: 실패
    OUT p_minute_id     BIGINT         -- 생성된 회의록 ID (성공 시)
)
BEGIN
    -- 에러 핸들러 변수
    DECLARE v_error INT DEFAULT 0;
    DECLARE v_minute_id BIGINT DEFAULT 0;

    -- 예외 발생 시 롤백 처리
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET v_error = 1;
        ROLLBACK;
        SET p_result_code = 1;  -- 실패
        SET p_minute_id = 0;
    END;

    -- --------------------------------------------------------
    -- 입력값 검증 (트랜잭션 시작 전)
    -- --------------------------------------------------------
    IF p_team_id IS NULL OR p_team_id = '' THEN
        SET p_result_code = 1;
        LEAVE SP_CREATE_MINUTES;
    END IF;

    IF p_audio_file_id IS NULL OR p_audio_file_id = 0 THEN
        SET p_result_code = 1;
        LEAVE SP_CREATE_MINUTES;
    END IF;

    IF p_minute_title IS NULL OR p_minute_title = '' THEN
        SET p_result_code = 1;
        LEAVE SP_CREATE_MINUTES;
    END IF;

    IF p_full_script IS NULL OR p_full_script = '' THEN
        SET p_result_code = 1;
        LEAVE SP_CREATE_MINUTES;
    END IF;

    IF p_ai_summary IS NULL OR p_ai_summary = '' THEN
        SET p_result_code = 1;
        LEAVE SP_CREATE_MINUTES;
    END IF;

    -- --------------------------------------------------------
    -- 트랜잭션 시작
    -- --------------------------------------------------------
    START TRANSACTION;

        -- Step 1. MINUTES 테이블 INSERT
        INSERT INTO `MINUTES` (
            `MINUTE_TITLE`,
            `FULL_SCRIPT`,
            `AI_SUMMARY`,
            `REG_DTM`,
            `TEAM_ID`
        ) VALUES (
            p_minute_title,
            p_full_script,
            p_ai_summary,
            p_reg_dtm,
            p_team_id
        );

        -- 생성된 MINUTE_ID 저장
        SET v_minute_id = LAST_INSERT_ID();

        -- Step 2. AUDIO_FILE에 MINUTE_ID 연결
        -- (음성파일은 트랜잭션 외부에서 이미 저장됨, 여기서 FK만 연결)
        UPDATE `AUDIO_FILE`
        SET    `MINUTE_ID` = v_minute_id
        WHERE  `AUDIO_FILE_ID` = p_audio_file_id;

        -- UPDATE 실패 체크 (해당 AUDIO_FILE이 없는 경우)
        IF ROW_COUNT() = 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'AUDIO_FILE not found';
        END IF;

    -- --------------------------------------------------------
    -- 전체 성공 시 커밋
    -- --------------------------------------------------------
    COMMIT;

    SET p_result_code = 0;      -- 성공
    SET p_minute_id = v_minute_id;

END$$

DELIMITER ;


-- ============================================================
-- 사용 예시 (Spring @Transactional 대신 프로시저 직접 호출 시)
-- ============================================================
--
-- CALL SP_CREATE_MINUTES(
--     'TEAM001',          -- p_team_id
--     12,                 -- p_audio_file_id (이미 저장된 음성파일 ID)
--     '2026-04-29 회의',  -- p_minute_title  (AI 자동생성)
--     '오늘 회의는...',   -- p_full_script   (STT 결과)
--     '핵심 요약: ...',   -- p_ai_summary    (AI 요약)
--     '2026-04-29 14:30:00', -- p_reg_dtm
--     @result_code,       -- OUT: 0(성공)/1(실패)
--     @minute_id          -- OUT: 생성된 MINUTE_ID
-- );
--
-- SELECT @result_code, @minute_id;
--
-- ============================================================


-- ============================================================
-- 전체 흐름 정리 (Spring + Python 연동 기준)
-- ============================================================
--
-- [1단계 - 트랜잭션 외부 / Spring]
--   클라이언트에서 녹음 완료 신호 수신
--   음성 파일 → S3 업로드
--   AUDIO_FILE INSERT (MINUTE_ID = NULL)
--   → AUDIO_FILE_ID 반환
--
-- [2단계 - Python AI 서버 호출 / 비동기]
--   음성파일 S3 경로 전달
--   STT 변환 → FULL_SCRIPT
--   AI 요약  → AI_SUMMARY
--   AI 제목  → MINUTE_TITLE
--   → 결과값 Spring 서버로 반환
--
-- [3단계 - 트랜잭션 내부 / Spring @Transactional]
--   SP_CREATE_MINUTES 호출
--   ├─ 성공: MINUTES INSERT + AUDIO_FILE.MINUTE_ID 업데이트 → COMMIT
--   └─ 실패: ROLLBACK (AUDIO_FILE은 보존, MINUTE_ID만 NULL 유지)
--
-- [실패 시 사용자 안내]
--   "회의록 생성에 실패했습니다."
--   음성파일은 보존되어 있으므로 [재시도] 버튼으로 재처리 가능
--
-- ============================================================