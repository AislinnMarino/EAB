WITH ranked_terms
     AS (SELECT DENSE_RANK ()
                OVER (
                   PARTITION BY A.INSTITUTION, A.EMPLID, A.STRM
                   ORDER BY
                      ---take a career equal to the billing career first
                      (CASE
                          WHEN A.ACAD_CAREER = A.BILLING_CAREER THEN '1'
                          ELSE '0'
                       END) DESC,
                      ---next, take the career with the highest number of units taken for progress
                      A.UNT_TAKEN_PRGRSS DESC,
                      ---next, take a degree granting primary academic program over a non degree granting one
                      (CASE
                          WHEN SUBSTR (A.ACAD_PROG_PRIMARY, 3, 1) <> 'N'
                          THEN
                             '1'
                          ELSE
                             '0'
                       END) DESC,
                      ---next, take UGRD
                      (CASE WHEN A.ACAD_CAREER = 'UGRD' THEN '1' ELSE '0' END) DESC,
                      ---next, assign lower rank to advanced certificates
                      (CASE
                          WHEN SUBSTR (A.ACAD_PROG_PRIMARY, 4, 1) <> '7'
                          THEN
                             '1'
                          ELSE
                             '0'
                       END) DESC,
                      ---order by program level
                      SUBSTR (A.ACAD_PROG_PRIMARY, 4, 1) DESC)
                   AS career_rank,
                a.*,
                tc.CML_TRANSFER_CREDITS,
                unts.eab_units_taken,
                unts.eab_units_earned
           FROM ps_rpt.ps_stdnt_car_term a
                JOIN (  SELECT rt.emplid,
                               rt.strm,
                               rt.institution,
                               rt.acad_career,
                               SUM (b.TRANSFER_CREDITS) AS CML_TRANSFER_CREDITS
                          FROM ps_rpt.ps_stdnt_car_term rt
                               JOIN
                               (SELECT EMPLID,
                                       STRM,
                                       institution,
                                       stdnt_car_nbr,
                                       acad_career,
                                       (  (  UNT_TRNSFR
                                           + TRF_PASSED_GPA
                                           + TRF_PASSED_NOGPA
                                           + UNT_TEST_CREDIT
                                           + UNT_OTHER)
                                        - TC_UNITS_ADJUST)
                                          AS TRANSFER_CREDITS
                                  FROM PS_RPT.PS_STDNT_CAR_TERM) b
                                  ON     b.EMPLID = rt.EMPLID
                                     AND rt.acad_career = b.acad_career
                                     AND rt.STDNT_CAR_NBR = B.STDNT_CAR_NBR
                                     AND rt.institution = B.INSTITUTION
                                     AND b.STRM <= rt.STRM
                      GROUP BY rt.emplid,
                               rt.strm,
                               rt.institution,
                               rt.acad_career) tc --join to create CML_TRANSFER_CREDITS
                   ON     a.emplid = tc.emplid
                      AND a.institution = tc.institution
                      AND a.strm = tc.strm
                      AND a.acad_career = tc.acad_career
                --units taken/units earned
                JOIN
                (  SELECT SCT.emplid AS emplid,
                          sct.acad_career AS acad_career,
                          sct.strm AS strm,
                          sct.institution AS institution,
                          SUM (NVL (enr.unt_taken, 0)) AS eab_units_taken,
                          SUM (NVL (enr2.unt_earned, 0)) AS eab_units_earned
                     FROM ps_rpt.ps_stdnt_car_term sct
                          FULL OUTER JOIN ps_rpt.ps_stdnt_enrl enr
                             ON     sct.emplid = enr.emplid
                                AND sct.acad_career = enr.acad_career
                                AND sct.strm = enr.strm
                                AND enr.stdnt_enrl_status = 'E'
                          FULL OUTER JOIN
                          (SELECT C.EMPLID,
                                  C.ACAD_CAREER,
                                  C.STRM,
                                  c.class_nbr,
                                  C.UNT_EARNED
                             FROM PS_RPT.PS_STDNT_ENRL C
                            WHERE     C.INSTITUTION = 'UBFLO'
                                  AND C.STDNT_ENRL_STATUS = 'E'
                                  AND C.EARN_CREDIT = 'Y'
                                  AND C.UNITS_ATTEMPTED <> 'I') enr2 -- in progress
                             ON     enr.emplid = enr2.emplid
                                AND enr.acad_career = enr2.acad_career
                                AND ENR.STRM = enr2.strm
                                AND enr.class_nbr = enr2.class_nbr
                    WHERE 1 = 1
                 GROUP BY sct.emplid,
                          sct.acad_career,
                          sct.strm,
                          sct.institution) unts
                   ON     unts.emplid = a.emplid
                      AND unts.strm = a.strm
                      AND unts.acad_career = a.acad_career
                      AND unts.institution = a.institution)
  SELECT *
    FROM ranked_terms rt
   WHERE rt.career_rank =
            (SELECT MIN (rt2.career_rank)
               FROM ranked_terms rt2
              WHERE rt.emplid = rt2.emplid AND rt.strm = rt2.strm)
