--21978 and 23932
select * from ps_rpt.cmp_section_meeting_v where course_ref_no='21969' and term_code='2269';
select * from ps_rpt.cmp_section_meeting_v where course_ref_no='21781' and term_code='2269';
select * from ps_rpt.cmp_section_v where course_number='101' and subject_cd='MGG' and term_code='2269' and course_type_code='REC' and section_name='A1' ;

--c1
select * from ps_rpt.cmp_section_meeting_v where course_ref_no='21978' and term_code='2269';
select * from ps_rpt.cmp_section_v where course_number='101' and subject_cd='MGG' and term_code='2269' and course_type_code='REC' and section_name='C1' ;


select * from ps_rpt.cmp_osf_cs_courses_v where subject_cd='MGG' and course_no='101';
select * from ps_rpt.ps_class_tbl where subject='MGG' and CATALOG_NBR =' 101LR';

select * from ps_rpt.cmp_section_v where term_code='2269' and course_ref_no='10002';
select * from ps_rpt.cmp_section_meeting_v where term_code='2269' and course_ref_no='10002';
select * from ps_rpt.cmp_osf_cs_courses_v where subject_cd='LAI' and course_no='640';

select * from ps_rpt.ps_class_tbl where subject='CHE' and strm='2269';
SELECT TO_CHAR
    (SYSDATE, 'MM-DD-YYYY ') "NOW"
     FROM DUAL;
select * from ps_rpt.cmp_section_v;
select class_stat from ps_rpt.ps_class_tbl where CLASS_STAT <> 'X';
select distinct class_stat from ps_rpt.ps_class_tbl; 

select count(*) from ps_rpt.cmp_section_meeting_v;
--section meeting base with sysdate change
SELECT NVL (c.STRM, '')
                 AS TERM_CODE,
             NVL (c.CLASS_NBR, '')
                 AS COURSE_REF_NO,
             NVL (mtg.CLASS_MTG_NBR, '')
                 AS MEET_NUMBER,
             NVL (mtg.ROOM, '')
                 AS MEET_ROOM_CODE,
             NVL (mtg.BLDG_NAME, '')
                 AS MEET_BUILDING_CODE,
             CASE WHEN mtg.MON = 'Y' THEN 'M' ELSE '' END
                 AS MEET_MONDAY,
             CASE WHEN mtg.TUES = 'Y' THEN 'T' ELSE '' END
                 AS MEET_TUESDAY,
             CASE WHEN mtg.WED = 'Y' THEN 'W' ELSE '' END
                 AS MEET_WEDNESDAY,
             CASE WHEN mtg.THURS = 'Y' THEN 'R' ELSE '' END
                 AS MEET_THURSDAY,
             CASE WHEN mtg.FRI = 'Y' THEN 'F' ELSE '' END
                 AS MEET_FRIDAY,
             CASE WHEN mtg.SAT = 'Y' THEN 'Sa' ELSE '' END
                 AS MEET_SATURDAY,
             CASE WHEN mtg.SUN = 'Y' THEN 'Su' ELSE '' END
                 AS MEET_SUNDAY,
             NVL (TO_CHAR (mtg.MEETING_TIME_START, 'HH24MI'), '')
                 AS START_TIME,
             NVL (TO_CHAR (mtg.MEETING_TIME_END, 'HH24MI'), '')
                 AS END_TIME,
             NVL (mtg.START_DT, '')
                 AS BEGIN_DATE,
             NVL (mtg.END_DT, '')
                 AS END_DATE,
             mtg.FACILITY_ID
                 AS LOCATION_CD,
             CASE
                 WHEN     (   (mtg.START_DT > TRUNC(SYSDATE - 3) )
                           OR (TRUNC(SYSDATE - 3)  BETWEEN mtg.START_DT AND mtg.END_DT))
                      AND c.CLASS_STAT <> 'X'
                 THEN
                     'Y'
                 ELSE
                     'N'
             END
                 AS IS_ACTIVE
        FROM ps_rpt.PS_CLASS_TBL c
             JOIN
             (SELECT m.CRSE_ID,
                     m.CLASS_SECTION,
                     m.CRSE_OFFER_NBR,
                     m.CLASS_MTG_NBR,
                     m.STRM,
                     m.session_code,
                     m.MEETING_TIME_START,
                     m.MEETING_TIME_END,
                     m.START_DT,
                     m.END_DT,
                     m.MON,
                     m.TUES,
                     m.WED,
                     m.THURS,
                     m.FRI,
                     m.SAT,
                     m.SUN,
                     f.FACILITY_ID,
                     f.BLDG_CD,
                     f.ROOM,
                     f.DESCR     AS BLDG_NAME
                FROM ps_rpt.PS_CLASS_MTG_PAT m
                     LEFT JOIN ps_rpt.PS_FACILITY_TBL f
                         ON m.FACILITY_ID = f.FACILITY_ID
                     LEFT JOIN ps_rpt.PS_BLDG_TBL b ON f.BLDG_CD = b.BLDG_CD
               WHERE     f.EFFDT = (SELECT MAX (ff.EFFDT)
                                      FROM ps_rpt.PS_FACILITY_TBL ff
                                     WHERE f.FACILITY_ID = ff.FACILITY_ID)
                     AND B.EFFDT = (SELECT MAX (bb.effdt)
                                      FROM ps_rpt.PS_BLDG_TBL bb
                                     WHERE B.BLDG_CD = bb.bldg_cd)) mtg
                 ON     c.CRSE_ID = mtg.CRSE_ID
                    AND c.STRM = mtg.STRM
                    AND c.CLASS_SECTION = mtg.CLASS_SECTION
                    AND c.CRSE_OFFER_NBR = mtg.CRSE_OFFER_NBR
                    AND c.session_code = mtg.session_code
                    
       WHERE     1 = 1
             AND C.ENRL_TOT > 0
              and c.CLASS_NBR ='21841' and c.STRM='2269'
             AND c.STRM >= (SELECT cf.lookback_term --Rolling filter to grab only terms up to a year ago
                              FROM ps_rpt.cmp_filter_current_v cf)
                            
    ORDER BY 2, 1;


--tie active flag to course or section flag
select * from ps_rpt.cmp_section_v where course_number='101' and subject_cd='MGG' and term_code='2269' and course_type_code='REC';
select * from ps_rpt.ps_class_tbl where subject='MGG' and CATALOG_NBR =' 101LR';


select * from ps_rpt.cmp_section_v where class_end_dt='31-AUG-2026';
--tied to term dates(this is bad)

SELECT TO_CHAR
    (SYSDATE, 'MM-DD-YYYY ') "NOW"
     FROM DUAL;

     SELECT TO_CHAR(SYSDATE, 'MM-DD-YYYY') FROM DUAL;
     SELECT SYSDATE FROM dual;
     select to_char(B.end_dt,'MM-DD-YYYY') from ps_rpt.PS_CLASS_MTG_PAT B ;

     --and B.start_dt='01-SEP-26'
                                      --and a.CLASS_NBR ='21841' and a.STRM='2269'
--section with sysdate change 
select * from ps_rpt.cmp_section_v;
WITH Section
        AS (  SELECT NVL (TRIM (a.CLASS_SECTION), '') AS SECTION_NAME,
                     NVL (TRIM (REGEXP_SUBSTR (a.catalog_nbr, '\d+')), '')
                        AS COURSE_NUMBER,
                     NVL (TRIM (a.SUBJECT), '') AS SUBJECT_CD,
                     NVL (a.CLASS_NBR, '') AS COURSE_REF_NO,
                     NVL (a.STRM, '') AS TERM_CODE,
                     NVL (a.SSR_COMPONENT, '') AS COURSE_TYPE_CODE,
                     ' ' AS SECTION_TAG,
                        a.subject
                     || ' '
                     || a.catalog_nbr
                     || ' '
                     || NVL (a.DESCR, '')
                        AS SECTION_TITLE,
                     N.Name AS Instructor_Name,
                     B.start_dt AS Class_Start_Dt,
                     B.end_dt AS Class_End_Dt,
                     'N' AS is_unlimited_seating,
                     ' ' AS section_type,
                     CASE WHEN to_char(B.end_dt,'MM-DD-YYYY')>= TO_CHAR(SYSDATE, 'MM-DD-YYYY') THEN 'Y' ELSE 'N' END
                        AS is_active
                FROM ps_rpt.PS_CLASS_TBL a
                     LEFT JOIN ps_rpt.PS_CLASS_MTG_PAT B
                        ON     B.CRSE_ID = A.CRSE_ID
                           AND B.CRSE_OFFER_NBR = A.CRSE_OFFER_NBR
                           AND B.STRM = A.STRM
                           AND B.SESSION_CODE = A.SESSION_CODE
                           AND B.CLASS_SECTION = A.CLASS_SECTION
                     LEFT JOIN (SELECT *
                                  FROM PS_RPT.PS_CLASS_INSTR
                                 WHERE INSTR_ROLE IN ('PI',
                                                      'SI',
                                                      'TA',
                                                      'CA')) I
                        ON (    a.CRSE_ID = I.CRSE_ID
                            AND a.STRM = I.STRM
                            AND a.CRSE_OFFER_NBR = I.CRSE_OFFER_NBR
                            AND a.SESSION_CODE = I.SESSION_CODE
                            AND a.CLASS_SECTION = I.CLASS_SECTION)
                     LEFT JOIN
                     (SELECT NA.EMPLID, NA.Name, NA.NAME_TYPE
                        FROM PS_RPT.PS_NAMES NA
                       WHERE     NA.NAME_TYPE =
                                    CASE
                                       WHEN EXISTS
                                               (SELECT *
                                                  FROM PS_RPT.PS_NAMES NMPRF
                                                 WHERE     NAME_TYPE = 'PRF'
                                                       AND EFF_STATUS = 'A'
                                                       AND NA.EMPLID =
                                                              NMPRF.EMPLID
                                                       AND NMPRF.EFFDT =
                                                              (SELECT MAX (
                                                                         NMPRF_1.EFFDT)
                                                                 FROM PS_RPT.PS_NAMES
                                                                      NMPRF_1
                                                                WHERE     NMPRF.EMPLID =
                                                                             NMPRF_1.EMPLID
                                                                      AND NMPRF.NAME_TYPE =
                                                                             NMPRF_1.NAME_TYPE
                                                                      AND NMPRF_1.EFFDT <=
                                                                             SYSDATE))
                                       THEN
                                          'PRF'
                                       ELSE
                                          'PRI'
                                    END
                             AND NA.EFFDT =
                                    (SELECT MAX (B_ED.EFFDT)
                                       FROM PS_RPT.PS_NAMES B_ED
                                      WHERE     NA.EMPLID = B_ED.EMPLID
                                            AND NA.NAME_TYPE = B_ED.NAME_TYPE
                                            AND B_ED.EFFDT <= SYSDATE)
                             AND NA.EFF_STATUS = 'A') N
                        ON (I.EMPLID = N.EMPLID)
               WHERE     1 = 1
                     AND a.enrl_tot > 0
                     AND a.STRM >= (SELECT cf.lookback_term --Rolling filter to grab only terms up to a year ago
                                      FROM ps_rpt.cmp_filter_current_v cf)
                                    and b.end_dt='31-AUG-26'  
            ORDER BY a.subject, a.catalog_nbr)
     SELECT SECTION_NAME,
            COURSE_NUMBER,
            SUBJECT_CD,
            COURSE_REF_NO,
            TERM_CODE,
            COURSE_TYPE_CODE,
            SECTION_TAG,
            SECTION_TITLE,
            SUBSTR(LISTAGG (INSTRUCTOR_NAME, '; ')
               WITHIN GROUP (ORDER BY INSTRUCTOR_NAME), 1, 64) --Adding this to concatenate instructor names on one row
               AS INSTRUCTOR_NAME,
            CLASS_START_DT,
            CLASS_END_DT,
            IS_UNLIMITED_SEATING,
            SECTION_TYPE,
            IS_ACTIVE
       FROM (SELECT DISTINCT INSTRUCTOR_NAME,
                             SECTION_NAME,
                             COURSE_NUMBER,
                             SUBJECT_CD,
                             COURSE_REF_NO,
                             TERM_CODE,
                             COURSE_TYPE_CODE,
                             SECTION_TAG,
                             SECTION_TITLE,
                             CLASS_START_DT,
                             CLASS_END_DT,
                             IS_UNLIMITED_SEATING,
                             SECTION_TYPE,
                             IS_ACTIVE
               FROM Section)
   GROUP BY SECTION_NAME,
            COURSE_NUMBER,
            SUBJECT_CD,
            COURSE_REF_NO,
            TERM_CODE,
            COURSE_TYPE_CODE,
            SECTION_TAG,
            SECTION_TITLE,
            CLASS_START_DT,
            CLASS_END_DT,
            IS_UNLIMITED_SEATING,
            SECTION_TYPE,
            IS_ACTIVE;