WITH MaxDatedPriNames
        AS (SELECT PRINAME.EMPLID,
                   CASE
                      WHEN NOT REGEXP_LIKE (PRINAME.FIRST_NAME, '^[A-Z]')
                      THEN
                         'X'
                      ELSE
                         COALESCE (PRINAME.FIRST_NAME, 'X')
                   END
                      AS FIRST_NAME,
                   PRINAME.MIDDLE_NAME,
                   PRINAME.LAST_NAME
              FROM PS_RPT.PS_NAMES PRINAME
             WHERE     PRINAME.NAME_TYPE = 'PRI'
                   AND PRINAME.EFF_STATUS = 'A'
                   AND PRINAME.EFFDT =
                          (SELECT MAX (PRIDT.EFFDT)
                             FROM PS_RPT.PS_NAMES PRIDT
                            WHERE     PRIDT.EMPLID = PRINAME.EMPLID
                                  AND PRIDT.NAME_TYPE = PRINAME.NAME_TYPE
                                  AND PRIDT.EFFDT <= SYSDATE)),
        MaxDatedPrefNames
        AS (SELECT PREFNAME.EMPLID,
                   CASE
                      WHEN NOT REGEXP_LIKE (PREFNAME.FIRST_NAME, '^[A-Z]')
                      THEN
                         'X'
                      ELSE
                         COALESCE (PREFNAME.FIRST_NAME, 'X')
                   END
                      AS FIRST_NAME,
                   PREFNAME.MIDDLE_NAME
              FROM PS_RPT.PS_NAMES PREFNAME
             WHERE     PREFNAME.NAME_TYPE = 'PRF'
                   AND PREFNAME.EFF_STATUS = 'A'
                   AND PREFNAME.EFFDT =
                          (SELECT MAX (PREFDT.EFFDT)
                             FROM PS_RPT.PS_NAMES PREFDT
                            WHERE     PREFDT.EMPLID = PREFNAME.EMPLID
                                  AND PREFDT.NAME_TYPE = PREFNAME.NAME_TYPE
                                  AND PREFDT.EFFDT <= SYSDATE)),
        MergedNames
        AS (SELECT PRI.EMPLID,
                   COALESCE (PREF.FIRST_NAME, PRI.FIRST_NAME) AS FIRST_NAME,
                   COALESCE (PREF.MIDDLE_NAME, PRI.MIDDLE_NAME)
                      AS MIDDLE_NAME,
                   PRI.LAST_NAME,
                   PNT.PRINCIPAL AS username
              FROM MaxDatedPriNames PRI
                   LEFT JOIN MaxDatedPrefNames PREF
                      ON PREF.EMPLID = PRI.EMPLID
                   LEFT JOIN DCE.PERSON_NUMBER_T PNT
                      ON PNT.PERSON_NUMBER = PRI.EMPLID)
   SELECT a.EMPLID AS STUDENT_ID,
          NVL (a.FIRST_NAME, '') AS FIRST_NAME,
          NVL (a.MIDDLE_NAME, '') AS MIDDLE_NAME,
          NVL (a.LAST_NAME, '') AS LAST_NAME,
          TO_CHAR (a.BIRTHDATE, 'YYYYMMDD') AS BIRTH_DT,
          NVL (a.SEX, '') AS GENDER,
          substr(NVL(pronouns.pronouns, ''), 1, 30) AS PRONOUNS,
          NVL (email.EMAIL_ADDR, '') AS EMAIL_ID,
          NVL (ethn.descr50, '') AS ETHNICITY_CD,
          CASE WHEN a.DT_OF_DEATH IS NULL THEN 'N' ELSE 'Y' END
             AS DECEASED_IND,
          '' AS field10,
          CASE
             WHEN     ctzn.COUNTRY = 'USA'
                  AND ctzn.CITIZENSHIP_STATUS NOT IN ('4')
             THEN
                'N'
             ELSE
                'Y'
          END
             AS INTERNATIONAL_IND,
          NVL (ctzn.COUNTRY, '') AS COUNTRY_CD,
          NVL (term.minTerm, '') AS INST_FIRST_TERM,
          NVL (hs.DESCR, '') AS HS_NAME,
          HS.CITY AS HS_CITY,
          HS.STATE AS HS_STATE,
          NVL (hs.CLASS_SIZE, '') AS HS_SIZE,
          NVL (hs.PERCENTILE, '') AS HS_PERCENTILE,
          NVL (hs.CLASS_RANK, '') AS HS_RANK,
          hs.EXT_GPA AS HS_GPA,
          '' AS field21,
          NVL (phone.PHONE, '') AS HOME_PHONE,
          '' AS field23,
          NVL (CELL.PHONE, '') AS MOBILE_PHONE,
          NVL (a.ADDRESS1, '') AS MAIL_ADDRESS_1,
          NVL (a.ADDRESS2, '') AS MAIL_ADDRESS2,
          NVL (a.CITY, '') AS MAIL_CITY,
          NVL (a.STATE, '') AS MAIL_STATE,
          NVL (SUBSTR (a.POSTAL, 1, 5), '') AS MAIL_ZIP_CODE,
          '' AS field30,
          '' AS field31,
          '' AS STUDENT_LEGACY_CD,
          NVL (admt.ADMIT_TYPE, '') AS STUDENT_ADMIT_CD,
          CASE WHEN admt.ADMIT_TYPE = '010' THEN 'Y' ELSE 'N' END
             AS TRANSFER_STUDENT_IND,
          CASE
             WHEN admt.ADMIT_TYPE = '010' THEN NVL (trnsInst.DESCR, '')
             ELSE ''
          END
             AS TRANSFER_INST_CD,
          CASE WHEN vet.EMPLID IS NULL THEN 'N' ELSE 'Y' END AS VETERAN_IND,
          CASE WHEN admt.ADMIT_TYPE = '021' THEN 'Y' ELSE 'N' END
             AS READMIT_IND,
          firstgen.first_gen AS FIRST_GEN_IND,
          NVL (SUBSTR (hs.POSTAL, 1, 5), '') AS HS_ZIP_CODE,
          NVL (SUBSTR (a.POSTAL, 1, 5), '') AS ADMISSION_ZIP_CODE,
          '' AS REGION_CD,
          NVL (activeInd.active_ind, 'N') AS ACTIVE_IND,
          NVL (a.username, '') AS username
     FROM (SELECT n.emplid AS emplid,
                  n.first_name AS first_name,
                  n.middle_name AS middle_name,
                  n.last_name AS last_name,
                  n.username AS username,
                  p.birthdate AS birthdate,
                  pe.sex AS sex,
                  p.dt_of_death AS dt_of_death,
                  AD.ADDRESS1 AS address1,
                  ad.address2 AS address2,
                  ad.city AS city,
                  ad.state AS state,
                  ad.postal AS postal
             FROM MergedNames n
                  JOIN PS_RPT.ps_PERSON p ON n.emplid = p.emplid
                  LEFT JOIN
                  (SELECT ADR.EMPLID,
                          ADR.ADDRESS1,
                          ADR.ADDRESS2,
                          ADR.CITY,
                          ADR.STATE,
                          ADR.POSTAL,
                          ADR.EFFDT,
                          ADR.EFF_STATUS,
                          /*always take active over inactive.
                            If more than 1 active take PERM, LOC, DORM, CAMP in that order.
                          */
                          DENSE_RANK ()
                          OVER (
                             PARTITION BY EMPLID
                             ORDER BY
                                EFF_STATUS,
                                CASE
                                   WHEN ADR.ADDRESS_TYPE = 'PERM' THEN 1
                                   WHEN ADR.ADDRESS_TYPE = 'LOC' THEN 2
                                   WHEN ADR.ADDRESS_TYPE = 'DORM' THEN 3
                                   WHEN ADR.ADDRESS_TYPE = 'CAMP' THEN 4
                                END)
                             AS ADDRESS_RANK
                     FROM PS_RPT.PS_ADDRESSES ADR
                    WHERE     ADR.ADDRESS_TYPE IN ('PERM',
                                                   'LOC',
                                                   'DORM',
                                                   'CAMP')
                          AND ADR.EFFDT =
                                 (SELECT MAX (ADDATE.EFFDT)
                                    FROM PS_RPT.PS_ADDRESSES ADDATE
                                   WHERE     ADDATE.EMPLID = ADR.EMPLID
                                         AND ADDATE.ADDRESS_TYPE =
                                                ADR.ADDRESS_TYPE)) AD
                     ON AD.EMPLID = n.EMPLID
                  LEFT JOIN ps_rpt.ps_pers_data_effdt pe
                     ON n.emplid = pe.emplid
            WHERE     AD.ADDRESS_RANK = 1
                  AND PE.EFFDT = (SELECT MAX (pe2.effdt)
                                    FROM ps_rpt.ps_pers_data_effdt pe2
                                   WHERE pe.emplid = pe2.emplid)) a
          --E-MAIL
          LEFT JOIN ps_rpt.PS_EMAIL_ADDRESSES email
             ON email.EMPLID = a.EMPLID AND email.E_ADDR_TYPE IN ('CAMP')
          --PHONE
          LEFT JOIN ps_rpt.PS_PERSONAL_PHONE phone
             ON phone.EMPLID = a.EMPLID AND PHONE_TYPE = 'PERM'
          --AND phone.PREF_PHONE_FLAG = 'Y'
          --MOBILE PHONE
          LEFT JOIN ps_rpt.ps_personal_phone cell
             ON cell.emplid = a.emplid AND CELL.phone_type = 'CELL'
          --PRONOUNS
          LEFT JOIN PS_RPT.PRONOUNS_V pronouns
             ON pronouns.EMPLID = a.emplid
          --ETHNICITY
          LEFT JOIN
          (SELECT EMPLID, descr50
             FROM ps_rpt.PS_DIVERS_ETHNIC e
                  JOIN ps_rpt.ps_ethnic_grp_tbl eg
                     ON     E.ETHNIC_GRP_CD = eg.ethnic_grp_cd
                        AND e.setid = eg.setid
            WHERE PRIMARY_INDICATOR = 'Y') ethn
             ON ethn.EMPLID = a.EMPLID
          --CITIZENSHIP
          LEFT JOIN
          (SELECT EMPLID, Country, Citizenship_Status
             FROM ps_rpt.PS_CITIZENSHIP a
            WHERE     Citizenship_Status <> ' '
                  AND Citizenship_Status = (SELECT MIN (Citizenship_Status)
                                              FROM ps_rpt.PS_CITIZENSHIP
                                             WHERE a.EMPLID = EMPLID)) ctzn
             ON ctzn.EMPLID = a.EMPLID
          --TERM OF ENROLLMENT
          LEFT JOIN (  SELECT EMPLID, MIN (STRM) AS minTerm
                         FROM ps_rpt.PS_STDNT_CAR_TERM
                     GROUP BY EMPLID) term
             ON term.EMPLID = a.EMPLID
          --Active Indicator information
          LEFT JOIN
          (SELECT DISTINCT (EMPLID) AS emplid, 'Y' AS active_ind
             FROM ps_rpt.PS_ACAD_PROG PRG
              WHERE     PROG_STATUS IN ('AC', 'CM', 'DC', 'DM', 'LA')
                  AND INSTITUTION = 'UBFLO'
                  AND PRG.EFFDT =
                         (SELECT MAX (PRG_ED.EFFDT)
                            FROM ps_rpt.PS_ACAD_PROG PRG_ED
                           WHERE     PRG_ED.EMPLID = PRG.EMPLID
                                 AND PRG_ED.ACAD_CAREER = PRG.ACAD_CAREER
                                 AND PRG_ED.STDNT_CAR_NBR = PRG.STDNT_CAR_NBR)
                  AND PRG.EFFSEQ =
                         (SELECT MAX (PRG_ES.EFFSEQ)
                            FROM ps_rpt.PS_ACAD_PROG PRG_ES
                           WHERE     PRG_ES.EMPLID = PRG.EMPLID
                                 AND PRG_ES.ACAD_CAREER = PRG.ACAD_CAREER
                                 AND PRG_ES.STDNT_CAR_NBR = PRG.STDNT_CAR_NBR
                                 AND PRG_ES.EFFDT = PRG.EFFDT)
                  AND emplid IN
                         (SELECT DISTINCT (EMPLID)
                            FROM ps_rpt.PS_STDNT_CAR_TERM ST
                                    WHERE ST.STRM in
                                    (SELECT distinct tv.ub_term_value
                                       FROM ps_rpt.ps_ub_term_val_tbl tv where acad_career = 'UGRD')))
          activeInd
             ON activeInd.EMPLID = a.EMPLID
          --HIGH SCHOOL 1
          LEFT JOIN
          (SELECT a.emplid AS myid,
                  a.CLASS_SIZE,
                  a.PERCENTILE,
                  a.CLASS_RANK,
                  a.EXT_GPA,
                  b.DESCR,
                  d.CITY,
                  d.STATE,
                  d.POSTAL,
                  a.EXT_ORG_ID,
                  c.LAST_SCH_ATTEND
             FROM ps_rpt.PS_EXT_ACAD_SUM a
                  LEFT JOIN ps_rpt.PS_EXT_ORG_TBL b
                     ON a.EXT_ORG_ID = b.EXT_ORG_ID
                  LEFT JOIN ps_rpt.PS_ADM_APPL_DATA c
                     ON     a.EXT_ORG_ID = c.LAST_SCH_ATTEND
                        AND a.EMPLID = c.EMPLID
                  LEFT JOIN ps_rpt.PS_ORG_LOC_VW d
                     ON b.EXT_ORG_ID = d.EXT_ORG_ID
            WHERE     a.EXT_CAREER = 'HS'
                  AND (   a.EXT_SUMM_TYPE = 'HSOV' --USES HIGH IF EXISTS, ELSE USES WHATEVER'S THERE
                       OR 0 =
                             (SELECT COUNT (b.EMPLID)
                                FROM ps_rpt.PS_EXT_ACAD_SUM b
                               WHERE     b.EMPLID = a.EMPLID
                                     AND b.EXT_SUMM_TYPE = 'HSOV'))
                  AND a.EXT_DATA_NBR =
                         (SELECT MAX (EXT_DATA_NBR)
                            FROM ps_rpt.PS_EXT_ACAD_SUM
                           WHERE     a.EMPLID = EMPLID
                                 AND a.EXT_ORG_ID = EXT_ORG_ID
                                 AND EXT_CAREER = a.ext_career
                                 AND ext_summ_type = a.ext_summ_type --NEW CODE DMK
                                                                    )
                  AND (   c.ADM_APPL_NBR =
                             (SELECT MAX (cc.ADM_APPL_NBR)
                                FROM ps_rpt.PS_ADM_APPL_DATA cc
                               WHERE     cc.EMPLID = NVL (c.EMPLID, 0)
                                     AND CC.ADMIT_TYPE IN ('001', '003')
                                     AND CC.LAST_SCH_ATTEND != ' ') --NEW CODE DMK
                       OR c.ADM_APPL_NBR IS NULL)
                  AND a.term_year =
                         (SELECT MAX (a2.term_year)
                            FROM ps_rpt.ps_ext_acad_sum a2
                           WHERE     a.emplid = a2.emplid
                                 AND A.EXT_CAREER = A2.EXT_CAREER
                                 AND A.EXT_SUMM_TYPE = A2.EXT_SUMM_TYPE)) hs
             ON hs.myID = a.EMPLID
          --READMIT FLAG
          LEFT JOIN
          (SELECT DISTINCT EMPLID
             FROM ps_rpt.PS_ACAD_PROG
            WHERE ACAD_CAREER IN ('UGRD') AND PROG_ACTION = 'RADM') readmit
             ON readmit.EMPLID = a.EMPLID
          --            --ADDRESSES MAIL
          --            LEFT JOIN
          --            (SELECT *
          --               FROM ps_rpt.PS_ADDRESSES a
          --              WHERE     ADDRESS_TYPE = 'PERM'
          --                    AND a.EFFDT =
          --                           (SELECT MAX (EFFDT)
          --                              FROM ps_rpt.PS_ADDRESSES b
          --                             WHERE     b.EMPLID = a.EMPLID
          --                                   AND ADDRESS_TYPE = 'PERM')) address1
          --               ON address1.EMPLID = a.EMPLID
          --            --ADDRESSES PERM
          --            LEFT JOIN
          --            (SELECT *
          --               FROM ps_rpt.PS_ADDRESSES a
          --              WHERE     ADDRESS_TYPE = 'PERM'
          --                    AND a.EFFDT =
          --                           (SELECT MAX (EFFDT)
          --                              FROM ps_rpt.PS_ADDRESSES b
          --                             WHERE     b.EMPLID = a.EMPLID
          --                                   AND ADDRESS_TYPE = 'PERM')) address2
          --               ON address2.EMPLID = a.EMPLID
          --ADMIT DATA
          LEFT JOIN (SELECT a.EMPLID, a.ADMIT_TYPE
                       FROM ps_rpt.PS_ADM_APPL_DATA a
                      --WHERE  a.ACAD_CAREER IN ( 'UGRD' ) --dmk changed to equal for potential performance issue
                      WHERE a.ADM_APPL_NBR = (SELECT MAX (ADM_APPL_NBR)
                                                FROM ps_rpt.PS_ADM_APPL_DATA
                                               WHERE a.EMPLID = EMPLID)) admt
             ON admt.EMPLID = a.EMPLID
          --TRANSFER INSTITUTION
          LEFT JOIN
          (SELECT DISTINCT a.EMPLID AS myID, b.DESCR, b.EXT_ORG_ID
             FROM PS_RPT.ps_adm_appl_data a, PS_RPT.ps_ext_org_tbl b
            WHERE     a.adm_creation_dt =
                         (SELECT MAX (adm_creation_dt)
                            FROM PS_RPT.ps_adm_appl_data c
                           WHERE     a.emplid = c.emplid
                                 AND a.acad_career = c.acad_career)
                  AND a.admit_type = '010'
                  AND a.last_sch_attend = b.ext_org_id
                  AND b.effdt = (SELECT MAX (b2.effdt)
                                   FROM ps_rpt.ps_ext_org_tbl b2
                                  WHERE B.EXT_ORG_ID = b2.ext_org_id)
                  AND b.eff_status = 'A') trnsInst
             ON trnsInst.myID = a.EMPLID
          --FIRST GENERATION INDICATOR
          LEFT JOIN
          (SELECT ip.EMPLID,
                  CASE
                     WHEN     ip.father_grade_lvl < '3'
                          AND ip.mother_grade_lvl < '3'
                     THEN
                        'Y'
                     ELSE
                        'N'
                  END
                     AS first_gen
             FROM ps_rpt.PS_ISIR_PARENT ip
            WHERE     ip.aid_year = (SELECT MIN (ipa.aid_year)
                                       FROM ps_rpt.ps_isir_parent ipa
                                      WHERE ip.emplid = ipa.emplid)
                  AND ip.effdt =
                         (SELECT MIN (ip2.effdt)
                            FROM ps_rpt.ps_isir_parent ip2
                           WHERE     ip.emplid = ip2.emplid
                                 AND ip.aid_year = ip2.aid_year)
                  AND ip.effseq =
                         (SELECT MIN (ip3.effseq)
                            FROM ps_rpt.ps_isir_parent ip3
                           WHERE     ip.emplid = ip3.emplid
                                 AND ip.aid_year = ip3.aid_year
                                 AND ip.effdt = ip3.effdt)) firstgen
             ON a.emplid = firstgen.emplid
          -- Veterans Ind
          LEFT JOIN
          (SELECT DISTINCT gh1.emplid AS EMPLID
             FROM ps_rpt.ps_stdnt_grps_hist gh1
                  JOIN ps_rpt.ps_stdnt_car_term ct ON gh1.emplid = CT.EMPLID
            WHERE     (gh1.stdnt_group = 'YRF' OR gh1.STDNT_GRouP LIKE ('V%'))
                  AND gh1.eff_status = 'A'
                  AND gh1.effdt <= SYSDATE
                  AND gh1.effdt = (SELECT MAX (gh2.effdt)
                                     FROM ps_rpt.ps_stdnt_grps_hist gh2
                                    WHERE gh1.emplid = gh2.emplid)
           UNION
           SELECT DISTINCT sf.emplid AS EMPLID
             FROM ps_rpt.PS_ITEM_SF sf
            WHERE SF.ITEM_TYPE IN ('000050000004',
                                   '000050000008',
                                   '000050000009',
                                   '000050000011',
                                   '000050000012',
                                   '000050000013',
                                   '000050000014',
                                   '000050000016',
                                   '000050000017',
                                   '000050000018',
                                   '000050000020',
                                   '000050000135',
                                   '000080000130',
                                   '000093200010',
                                   '000093200011',
                                   '000093200012',
                                   '000093200013',
                                   '000050000005',
                                   '000050000006',
                                   '000050000007',
                                   '000050000010',
                                   '000050000015',
                                   '000050000019',
                                   '000080000131',
                                   '000080000115',
                                   '000092000015',
                                   '000092000025',
                                   '000092000040',
                                   '000092100237',
                                   '000093103810',
                                   '000093200005',
                                   '000093200006',
                                   '000093200007')) vet
             ON a.EMPLID = vet.EMPLID