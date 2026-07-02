SELECT a.EMPLID AS STUDENT_ID,
       NVL (a.STRM, ' ') AS TERM_ID,
       collegecode.ACAD_GROUP AS COLLEGE_CD,
       'UB' AS CAMPUS_CD,
       NVL (org.acad_org, ' ') AS DEPARTMENT_CD,
       NVL (a.ACADEMIC_LOAD, ' ') AS TIME_STATUS_CD,
       NVL (res.RESIDENCY, ' ') AS RESIDENCY_CD,
       NVL (a.ACAD_LEVEL_BOT, ' ') AS STUDENT_CLASSIFICATION_CD,
       CASE WHEN fa_applied.efc_status != 'R' THEN 'Y' ELSE 'N' END -- rejected status (R)
          AS FIN_AID_APPLY_IND,
       CASE
          WHEN housing.housing_dt <= termtbl.term_end_dt THEN 'Y'
          ELSE 'N'
       END
          AS housing_ind,
       CASE WHEN FA_BALANCE > 0 THEN 'Y' ELSE 'N' END AS FIN_AID_AWARD_IND,
       CASE
          WHEN (a.UNT_OTHER + a.UNT_TAKEN_PRGRSS + a.UNT_TAKEN_PRGRSS + a.UNT_PASSD_PRGRSS) =
                  0
          THEN
             'N'
          ELSE
             'Y'
       END
          AS REGISTERED_IND,
       ' ' AS FIELD13,
       CASE
          WHEN (    a.UNT_TAKEN_PRGRSS = 0
                AND (  a.UNT_TRNSFR
                     + a.TRF_PASSED_GPA
                     + a.TRF_PASSED_NOGPA
                     + a.UNT_TEST_CREDIT
                     + a.UNT_OTHER
                     + TOT_TRNSFR) <> 0)
          THEN
             'Y'
          ELSE
             'N'
       END
          AS TRANSFER_TERM_IND,
       CASE WHEN dean.EMPLID IS NOT NULL THEN 'Y' ELSE 'N' END
          AS DEANS_LIST_IND,
       NVL (p.DEGR_CHKOUT_STAT, ' ') AS DEGREE_APP_STATUS_CD,
       ' ' AS GRADUATED_IND,
       NVL (a.UNT_TAKEN_PRGRSS, 0) AS INST_REGISTERED_CRED,
       NVL (a.TOT_TRNSFR, 0) AS TRANSF_EARNED_CRED,
       NVL (a.eab_units_taken, 0) AS inst_attempted_cred,
       NVL (a.eab_units_earned, 0) AS inst_earned_cred,
       ' ' AS FIELD22,
       NVL (a.SSR_CUM_EN_GPA, 0) AS INST_GPA,
       'Institutional' AS GPA_TYPE,
       'Y' AS OFFICIAL_GPA_IND,
       ' ' AS MAJOR_CD_1,
       ' ' AS MAJOR_CD_2,
       ' ' AS MAJOR_CD_3,
       ' ' AS FIELD29,
       ' ' AS CONCENTRATION_CD_1,
       ' ' AS CONCENTRATION_CD_2,
       ' ' AS CONCENTRATION_CD_3,
       ' ' AS FIELD33,
       NVL (p.exp_grad_term, ' ') AS intended_grad_year,
       ' ' AS FIELD35,
       CASE WHEN a.WITHDRAW_DATE IS NULL THEN 'N' ELSE 'Y' END
          AS WITHDRAWAL_IND,
       NVL (a.WITHDRAW_REASON, ' ') AS WITHDRAWAL_REASON,
       NVL (TO_CHAR (regStart.FIRST_ENRL_DT, 'YYYYMMDD'), ' ')
          AS REGISTRATION_START_DT,
       NVL (TO_CHAR (regEnd.LST_WD_WO_PEN_DT, 'YYYYMMDD'), ' ')
          AS REGISTRATION_END_DT,
       ' ' AS FIELD40,
       ' ' AS DEGREE_CD_1,
       ' ' AS DEGREE_CD_2,
       ' ' AS DEGREE_CD_3,
       ' ' AS FIELD44,
       ' ' AS FIELD45,
       NVL (a.CML_TRANSFER_CREDITS, 0) AS TRANSF_EARNED_CRED_CML,
         NVL (
            SUM (
               a.eab_units_earned)
            OVER (PARTITION BY a.emplid, a.acad_career
                  ORDER BY a.emplid, a.acad_career, a.strm
                  RANGE UNBOUNDED PRECEDING),
            0)
       + NVL (a.cml_transfer_credits, 0)
          AS overall_earned_cred_cml,
       NVL (
          SUM (
             a.eab_units_earned)
          OVER (PARTITION BY a.emplid, a.acad_career
                ORDER BY a.emplid, a.acad_career, a.strm
                RANGE UNBOUNDED PRECEDING),
          0)
          AS inst_earned_cred_cml,
       SUM (
          NVL (a.eab_units_taken, 0))
       OVER (PARTITION BY a.emplid, a.acad_career
             ORDER BY a.emplid, a.acad_career, a.strm
             RANGE UNBOUNDED PRECEDING)
          AS inst_attempted_cred_cml,
	   case when trim(acadStnd.ACAD_STNDNG_ACTN) is null then 'UNKN' else acadStnd.ACAD_STNDNG_ACTN end AS ACADEMIC_STANDING_CD,
       ' ' AS COLLEGE_CD_2,
       ' ' AS COLLEGE_CD_3,
       ' ' AS FIELD53,
       ' ' AS FIELD54,
       ' ' AS FIELD55,
       ' ' AS FIELD56,
       ' ' AS FIELD57,
       NVL (a.ACAD_CAREER, ' ') AS LEVEL_CD,
       ' ' AS STUDENT_TYPE_CD,
       ' ' AS STUDENT_STATUS,
       'UB' AS GROUP_ID,
       ' ' AS GRADUATE_STUDENT_IND
  FROM PS_RPT.CMP_STU_CAR_TERM_RANKED_MV a         -- ranked ps_stdnt_car_term
       --College Code
       JOIN (SELECT a.ACAD_GROUP, a.ACAD_PROG
               FROM PS_RPT.PS_ACAD_PROG_TBL a
              WHERE EFFDT = (SELECT MAX (EFFDT)
                               FROM PS_RPT.PS_ACAD_PROG_TBL
                              WHERE a.ACAD_PROG = ACAD_PROG)) collegecode
          ON a.ACAD_PROG_PRIMARY = collegecode.ACAD_PROG
       JOIN PS_RPT.PS_TERM_TBL termtbl
          ON a.STRM = termtbl.STRM AND a.ACAD_CAREER = termtbl.ACAD_CAREER
       -- RESIDENCY
       LEFT JOIN
       (SELECT t.EMPLID,
               t.strm,
               t.acad_career,
               r.residency,
               r.effective_term
          FROM PS_RPT.ps_stdnt_car_term t
               JOIN PS_RPT.PS_RESIDENCY_OFF r
                  ON     t.emplid = r.emplid
                     AND T.ACAD_CAREER = r.acad_career
                     AND r.effective_term =
                            (SELECT MAX (r2.effective_term)
                               FROM PS_RPT.ps_residency_off r2
                              WHERE     r.emplid = r2.emplid
                                    AND r.acad_career =
                                           r2.acad_career
                                    AND r2.effective_term <= t.strm)) res
          ON     a.EMPLID = res.EMPLID
             AND a.strm = res.strm
             AND a.acad_career = res.acad_career
       JOIN PS_RPT.ps_term_tbl term
          ON A.STRM = term.strm AND a.acad_career = term.acad_career
       JOIN PS_RPT.PS_acad_prog p
          ON     a.emplid = p.emplid
             AND a.acad_career = p.acad_career
             AND a.stdnt_car_nbr = P.STDNT_CAR_NBR
             AND a.acad_prog_primary = p.acad_prog
             AND P.EFFDT =
                    (SELECT MAX (p2.effdt)
                       FROM PS_RPT.ps_acad_prog p2
                      WHERE     p.emplid = p2.emplid
                            AND p.acad_career = p2.acad_career
                            AND p.stdnt_car_nbr = p2.stdnt_car_nbr
                            AND p.acad_prog = p2.acad_prog
                            AND p2.effdt <= term.ssr_trmac_last_dt)
             AND P.EFFSEQ =
                    (SELECT MAX (EFFSEQ)
                       FROM PS_RPT.PS_ACAD_PROG P3
                      WHERE     P.EMPLID = P3.EMPLID
                            AND P.ACAD_CAREER = P3.ACAD_CAREER
                            AND P.STDNT_CAR_NBR = P3.STDNT_CAR_NBR
                            AND P.ACAD_PROG = P3.ACAD_PROG
                            AND P.EFFDT = P3.EFFDT)
       JOIN (SELECT *
               FROM (SELECT emplid,
                            acad_career,
                            stdnt_car_nbr,
                            effdt,
                            effseq,
                            acad_plan,
                            DENSE_RANK ()
                               OVER (PARTITION BY emplid,
                                                  acad_career,
                                                  stdnt_car_nbr,
                                                  effdt,
                                                  effseq
                                     ORDER BY plan_sequence)
                               AS RANK
                       FROM PS_RPT.ps_acad_plan p)
              WHERE RANK = 1) pl
          ON     P.EMPLID = pl.emplid
             AND P.ACAD_CAREER = pl.acad_career
             AND p.stdnt_car_nbr = pl.stdnt_car_nbr
             AND p.effdt = pl.effdt
             AND p.effseq = pl.effseq
       LEFT JOIN
       (SELECT po.acad_plan, po.acad_org
          FROM PS_RPT.ps_acad_plan_owner po
         WHERE     PO.ACAD_ORG NOT IN ('1900', '1901', '1902')
               AND po.effdt = (SELECT MIN (po2.effdt)
                                 FROM PS_RPT.ps_acad_plan_owner po2
                                WHERE po.acad_plan = po2.acad_plan)) org
          ON pl.acad_plan = org.acad_plan
       --                     ) a
       --DEAN'S LIST
       LEFT JOIN (SELECT DISTINCT EMPLID, STRM                  --, AWARD_CODE
                    FROM PS_RPT.PS_HONOR_AWARD_CS
                   WHERE AWARD_CODE IN ('DEANL')) dean
          ON a.EMPLID = dean.EMPLID AND a.STRM = dean.STRM
       --ACADEMIC STANDING
       LEFT JOIN
       (SELECT EMPLID,
               STRM,
               ACAD_STNDNG_ACTN,
               S.ACAD_CAREER
          FROM PS_RPT.PS_ACAD_STDNG_ACTN s
         WHERE     EFFDT = (SELECT MAX (EFFDT)
                              FROM PS_RPT.PS_ACAD_STDNG_ACTN b
                             WHERE b.EMPLID = s.EMPLID AND b.STRM = s.STRM)
               AND EFFSEQ = (SELECT MAX (EFFSEQ)
                               FROM PS_RPT.PS_ACAD_STDNG_ACTN b
                              WHERE b.EMPLID = s.EMPLID AND b.STRM = s.STRM))
       acadStnd
          ON     acadStnd.EMPLID = a.EMPLID
             AND acadStnd.STRM = a.STRM
             AND a.acad_career = acadStnd.acad_career
       --REGISTRATION END
       LEFT JOIN
       (  SELECT STRM, acad_career, MIN (LST_WD_WO_PEN_DT) AS LST_WD_WO_PEN_DT
            FROM PS_RPT.PS_ACAD_CALTRM_TBL
        GROUP BY STRM, acad_career) regEnd
          ON regEnd.STRM = a.STRM AND a.acad_career = regEnd.acad_career
       --REGISTRATION START
       LEFT JOIN
       (  SELECT STRM, acad_career, MIN (FIRST_ENRL_DT) AS FIRST_ENRL_DT
            FROM PS_RPT.PS_SESSION_TBL
        GROUP BY STRM, acad_career) regStart
          ON regStart.STRM = a.STRM AND a.acad_career = regStart.acad_career
       -- FINANCIAL AID INDR
       LEFT JOIN
       (  SELECT A2.EMPLID, strm, SUM (A2.DISBURSED_BALANCE) AS FA_BALANCE
            FROM PS_RPT.PS_STDNT_DISB_VW1 A2
                 INNER JOIN
                 (SELECT *
                    FROM (SELECT itf.*,
                                 DENSE_RANK ()
                                 OVER (PARTITION BY SETID, ITEM_TYPE, AID_YEAR
                                       ORDER BY effdt DESC)
                                    AS RANK
                            FROM PS_RPT.PS_ITEM_TYPE_FA itf
                           WHERE     EFFDT <= SYSDATE
                                 AND (   FIN_AID_TYPE <
                                            'W' || SUBSTR (UID, 1, 0)
                                      OR FIN_AID_TYPE > 'W')) V
                   WHERE RANK = 1) B
                    ON     A2.AID_YEAR = B.AID_YEAR
                       AND A2.ITEM_TYPE = B.ITEM_TYPE
                       AND B.SETID = A2.SETID
           WHERE A2.disbursed_balance > 0
        GROUP BY A2.EMPLID, A2.strm) FA
          ON a.emplid = fa.emplid AND a.strm = fa.strm
       --Financial Aid Apply Indicator
       LEFT JOIN  -- leave this as UGRD since it similar to the term val issue
       (SELECT A.EMPLID,
               a.efc_status,
               ay.aid_year,
               ay.strm
          FROM ps_rpt.PS_ISIR_CONTROL A
               JOIN
               (  SELECT strm,
                         MAX (aid_year) AS aid_year,
                         acad_career
                    FROM PS_RPT.PS_AID_YR_CAR_TERM AY
                GROUP BY strm, acad_career) ay
                  ON a.aid_year = ay.aid_year
         WHERE     (    A.EFFDT =
                           (SELECT MAX (A_ED.EFFDT)
                              FROM ps_rpt.PS_ISIR_CONTROL A_ED
                             WHERE     A.EMPLID = A_ED.EMPLID
                                   AND A.INSTITUTION = A_ED.INSTITUTION
                                   AND A.AID_YEAR = A_ED.AID_YEAR
                                   AND A_ED.EFFDT <= SYSDATE)
                    AND A.EFFSEQ =
                           (SELECT MAX (A_ES.EFFSEQ)
                              FROM ps_rpt.PS_ISIR_CONTROL A_ES
                             WHERE     A.EMPLID = A_ES.EMPLID
                                   AND A.INSTITUTION = A_ES.INSTITUTION
                                   AND A.AID_YEAR = A_ES.AID_YEAR
                                   AND A.EFFDT = A_ES.EFFDT))
               AND a.efc_status != 'R'                      -- rejected status
               AND AY.ACAD_CAREER = 'UGRD') FA_applied
          ON a.emplid = fa_applied.emplid AND a.strm = fa_applied.strm
       --housing indicator
       LEFT JOIN
       (SELECT addr.emplid, addr.effdt AS housing_dt
          FROM ps_rpt.ps_addresses addr
         WHERE     addr.address_type = 'DORM'
               AND addr.eff_status = 'A'
               AND addr.effdt = (SELECT MAX (addr2.effdt)
                                   FROM ps_rpt.ps_addresses addr2
                                  WHERE addr2.emplid = addr.emplid)) HOUSING
          ON housing.emplid = a.emplid