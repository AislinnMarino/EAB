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
                 WHEN     (   (mtg.START_DT > SYSDATE)
                           OR (SYSDATE BETWEEN mtg.START_DT AND mtg.END_DT))
                      AND c.CLASS_STAT <> 'X'
                 THEN
                     'Y'
                 ELSE
                     'N'
             END
                 AS IS_ACTIVE
        FROM PS_CLASS_TBL c
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
                FROM PS_CLASS_MTG_PAT m
                     LEFT JOIN PS_FACILITY_TBL f
                         ON m.FACILITY_ID = f.FACILITY_ID
                     LEFT JOIN PS_BLDG_TBL b ON f.BLDG_CD = b.BLDG_CD
               WHERE     f.EFFDT = (SELECT MAX (ff.EFFDT)
                                      FROM PS_FACILITY_TBL ff
                                     WHERE f.FACILITY_ID = ff.FACILITY_ID)
                     AND B.EFFDT = (SELECT MAX (bb.effdt)
                                      FROM PS_BLDG_TBL bb
                                     WHERE B.BLDG_CD = bb.bldg_cd)) mtg
                 ON     c.CRSE_ID = mtg.CRSE_ID
                    AND c.STRM = mtg.STRM
                    AND c.CLASS_SECTION = mtg.CLASS_SECTION
                    AND c.CRSE_OFFER_NBR = mtg.CRSE_OFFER_NBR
                    AND c.session_code = mtg.session_code
       WHERE     1 = 1
             AND C.ENRL_TOT > 0
             AND c.STRM >= (SELECT cf.lookback_term --Rolling filter to grab only terms up to a year ago
                              FROM ps_rpt.cmp_filter_current_v cf)
    ORDER BY 2, 1