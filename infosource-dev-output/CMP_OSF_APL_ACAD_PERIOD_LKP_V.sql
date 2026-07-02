SELECT DISTINCT
             a.STRM                                   AS TERM_ID,
             a.DESCR                                  AS TERM_DESC,
             a.ACAD_YEAR                              AS ACADEMIC_YEAR,
             a.DESCR                                  AS ACADEMIC_YEAR_DESC,
             CASE
                 WHEN a.DESCR LIKE 'Spring%' THEN 'Spring'
                 WHEN a.DESCR LIKE 'Summer%' THEN 'Summer'
                 WHEN a.DESCR LIKE 'Fall%' THEN 'Fall'
                 WHEN a.DESCR LIKE 'Winter%' THEN 'Winter'
                 ELSE 'n/a'
             END                                      AS TERM_TYPE --, SUBSTRING(a.DESCR, 1, CHARINDEX(a.DESCR, ' ') - 1) AS TERM_TYPE
                                                                  ,
             TO_CHAR (a.TERM_BEGIN_DT, 'YYYYMMDD')    AS TERM_START_DATE,
             TO_CHAR (a.TERM_END_DT, 'YYYYMMDD')      AS TERM_END_DATE,
             TO_CHAR (a.FIRST_ENRL_DT, 'YYYYMMDD')    AS REGISTRATION_START_DT,
             TO_CHAR (a.LAST_ENRL_DT, 'YYYYMMDD')     AS REGISTRATION_END_DT,
             IS_ACTIVE
        FROM (  SELECT term.STRM,
                       term.DESCR,
                       term.ACAD_YEAR,
                       MIN (term.TERM_BEGIN_DT)    AS TERM_BEGIN_DT,
                       MIN (term.TERM_END_DT)      AS TERM_END_DT,
                       sess.FIRST_ENRL_DT,
                       sess.LAST_ENRL_DT,
                       CASE
                           WHEN SESS.SESS_END_DT >= SYSDATE THEN 'Y'
                           ELSE 'N'
                       END                         AS IS_ACTIVE
                  FROM ps_rpt.PS_TERM_TBL term
                       JOIN ps_rpt.ps_session_tbl sess ON term.strm = sess.strm
                 WHERE     term.ACAD_CAREER IN ('UGRD')
                       AND sess.session_code IN ('1', '12W', '15D', '3W1')
                       AND sess.acad_career = 'UGRD' --Update, member-specific
              GROUP BY term.STRM,
                       term.DESCR,
                       term.ACAD_YEAR,
                       sess.FIRST_ENRL_DT,
                       sess.LAST_ENRL_DT,
                       SESS.SESS_END_DT) a
       WHERE 1 = 1
    ORDER BY TERM_ID DESC