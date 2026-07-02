WITH
    AcadGroups
    AS
        (                     --max non future dated row with lowest offer nbr
         SELECT OFFR.CRSE_ID, OFFR.ACAD_GROUP
           FROM PS_RPT.PS_CRSE_OFFER OFFR
          WHERE     OFFR.EFFDT =
                    (SELECT MAX (ODT.EFFDT)
                       FROM PS_RPT.PS_CRSE_OFFER ODT
                      WHERE     ODT.CRSE_ID = OFFR.CRSE_ID
                            AND ODT.EFFDT <= SYSDATE)
                AND OFFR.CRSE_OFFER_NBR =
                    (SELECT MIN (ONBR.CRSE_OFFER_NBR)
                       FROM PS_RPT.PS_CRSE_OFFER ONBR
                      WHERE     ONBR.CRSE_ID = OFFR.CRSE_ID
                            AND ONBR.EFFDT = OFFR.EFFDT)),
    CrseData
    AS
        (                                --cat and offer data excluding future
         SELECT DISTINCT CAT.CRSE_ID,
                         CAT.EFFDT,
                         CAT.SSR_COMPONENT,
                         OFFR.SUBJECT,
                         OFFR.CATALOG_NBR,
                         CAT.COURSE_TITLE_LONG,
                         TO_CHAR (CAT.DESCRLONG)     AS DESCR,
                         CAT.EFF_STATUS,
                         CAT.UNITS_MAXIMUM,
                         CAT.UNITS_MINIMUM,
                         AcadGroups.ACAD_GROUP
           FROM PS_RPT.PS_CRSE_CATALOG  CAT
                LEFT JOIN PS_RPT.PS_CRSE_OFFER OFFR
                    ON OFFR.CRSE_ID = CAT.CRSE_ID AND OFFR.EFFDT = CAT.EFFDT
                LEFT JOIN AcadGroups ON AcadGroups.CRSE_ID = CAT.CRSE_ID
          WHERE CAT.EFFDT <= SYSDATE),
    CrseDataEffdt
    AS
        (  SELECT crse_id, MAX (effdt) AS Effdt, subject
             FROM crsedata
         GROUP BY crse_id, subject),
    CrseEffComponent
    AS
        (SELECT cd.crse_id,
                ce.Effdt,
                cd.subject,
                cd.catalog_nbr,
                cd.course_title_long,
                cd.descr,
                cd.eff_status,
                cd.units_maximum,
                cd.units_minimum,
                cd.acad_group,
                cd.ssr_component
           FROM crsedata cd, crsedataeffdt ce
          WHERE     cd.crse_id = ce.crse_id
                AND cd.effdt = ce.effdt
                AND cd.subject = ce.subject),
    --crse_component
    --AS
    --    (SELECT c.*, com.ssr_component
    --       FROM CrseData  c
    --            JOIN (SELECT DISTINCT crse_id, ssr_component
    --                    FROM ps_rpt.ps_class_tbl
    --                  UNION
    --                  SELECT DISTINCT crse_id, ssr_component
    --                    FROM ps_rpt.ps_crse_component) com
    --                ON c.crse_id = com.crse_id),
    ExtDataFormat
    AS
        (                                            --match data to file spec
         SELECT ACAD_GROUP           AS COLLEGE_CD,
                CRSE_ID,
                EFFDT,
                SUBJECT              AS SUBJECT_CD,
                CASE
                    WHEN CATALOG_NBR LIKE '%999%' THEN CATALOG_NBR
                    ELSE REGEXP_SUBSTR (CATALOG_NBR, '\d+')
                END                  AS COURSE_NO,
                CATALOG_NBR,
                COURSE_TITLE_LONG    AS TITLE,
                UNITS_MINIMUM        AS CREDIT_MIN,
                UNITS_MAXIMUM        AS CREDIT_MAX,
                'NA'                 AS DEPARTMENT_CD,
                EFF_STATUS           AS COURSE_STATUS_CD,
                SSR_COMPONENT        AS COURSE_TYPE_CD,
                DESCR
           FROM CrseEffComponent),
    RankedData
    AS
        (                                  --ranking for preventing duplicates
         --for identical rows with different status always take ACTIVE first
         --then take longer catalog nbr    (REMOVING THIS 3/5/21)
         --then take later date
         --then take larger crse_id
         SELECT EDF.COLLEGE_CD,
                EDF.CRSE_ID,
                EDF.SUBJECT_CD,
                EDF.COURSE_NO,
                EDF.EFFDT,
                EDF.TITLE,
                EDF.CREDIT_MIN,
                EDF.CREDIT_MAX,
                EDF.DEPARTMENT_CD,
                EDF.COURSE_STATUS_CD,
                EDF.COURSE_TYPE_CD,
                EDF.DESCR,
                DENSE_RANK ()
                    OVER (
                        PARTITION BY SUBJECT_CD, COURSE_NO, COURSE_TYPE_CD
                        ORDER BY
                            COURSE_STATUS_CD ASC, -- LENGTH (CATALOG_NBR) DESC,
                                                  EFFDT DESC, CRSE_ID DESC)    RANK_NO
           FROM ExtDataFormat EDF),
    --add a max effdt row?
    --we need to find the maxeffdt and then join that to get the newest row
    RankedDataEffDt
    AS
        (  SELECT college_cd,
                  crse_id,
                  subject_cd,
                  course_no,
                  MAX (effdt)     AS effdt,
                  title,
                  credit_min,
                  credit_max,
                  department_cd,
                  course_status_cd,
                  descr,
                  rank_no
             FROM RankedData
         GROUP BY college_cd,
                  crse_id,
                  subject_cd,
                  course_no,
                  title,
                  credit_min,
                  credit_max,
                  department_cd,
                  course_type_cd,
                  descr,
                  rank_no),
    RankedDataActive
    AS
        (  SELECT college_cd,
                  crse_id,
                  subject_cd,
                  course_no,
                  MAX (effdt)     AS effdt,
                  title,
                  credit_min,
                  credit_max,
                  department_cd,
                  course_status_cd,
                  course_type_cd,
                  descr,
                  rank_no
             FROM RankedData
         GROUP BY college_cd,
                  crse_id,
                  subject_cd,
                  course_no,
                  title,
                  credit_min,
                  credit_max,
                  department_cd,
                  course_type_cd,
                  descr,
                  course_status_cd,
                  rank_no --grouping by course status cd is still showing inactive
           HAVING course_status_cd = 'A'),
    correct_crse_info
    AS
        (SELECT DISTINCT
                COLLEGE_CD,
                TRIM (BOTH ' ' FROM SUBJECT_CD)                                SUBJECT_CD,
                TRIM (BOTH ' ' FROM COURSE_NO)                                 COURSE_NO,
                TITLE,
                EFFDT,
                CREDIT_MIN,
                CREDIT_MAX,
                DEPARTMENT_CD,
                COURSE_STATUS_CD,
                COURSE_TYPE_CD,
                TRANSLATE (DESCR, CHR (10) || CHR (11) || CHR (13), '    ')    AS descr -- replaces newline, tab and carriage return with space
           FROM RankedDataActive
          WHERE RANK_NO = 1 AND course_status_cd = 'A'),
    max_effdt_descr
    AS
        (SELECT college_cd,
                SUBJECT_CD,
                COURSE_NO,
                effdt,
                title     AS title,
                descr     AS descr,
                COURSE_TYPE_CD
           FROM correct_crse_info
          WHERE (college_cd,
                 SUBJECT_CD,
                 COURSE_NO,
                 effdt,
                 COURSE_TYPE_CD) IN (  SELECT college_cd,
                                              SUBJECT_CD,
                                              COURSE_NO,
                                              MAX (effdt)     AS effdt,
                                              COURSE_TYPE_CD
                                         FROM correct_crse_info
                                     GROUP BY college_cd,
                                              SUBJECT_CD,
                                              COURSE_NO,
                                              COURSE_TYPE_CD))
SELECT DISTINCT cc.college_cd,
                cc.SUBJECT_CD,
                cc.COURSE_NO,
                mx.title,
                cc.CREDIT_MIN,
                cc.CREDIT_MAX,
                cc.DEPARTMENT_CD,
                cc.COURSE_STATUS_CD,
                cc.COURSE_TYPE_CD,
                mx.descr
  FROM correct_crse_info  cc
       LEFT OUTER JOIN max_effdt_descr mx
           ON     cc.college_cd = mx.college_cd
              AND cc.SUBJECT_CD = mx.SUBJECT_CD
              AND cc.COURSE_NO = mx.COURSE_NO
              AND cc.COURSE_TYPE_CD = mx.COURSE_TYPE_CD