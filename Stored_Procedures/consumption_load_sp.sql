
CREATE OR REPLACE PROCEDURE "SP_LOAD_CONSUMPTION"()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS '
BEGIN
    ----------------------------------------------------------------
    -- 0. (truncate-equivalent) EXISTING VIEWS
    ----------------------------------------------------------------
    TRUNCATE VIEW IF EXISTS V_COMPANY_METRICS;
    TRUNCATE VIEW IF EXISTS V_GLOBAL_METRICS;
    TRUNCATE VIEW IF EXISTS V_MASTER_ANALYTICS;

    ----------------------------------------------------------------
    -- 1. MASTER ANALYTICS VIEW
    ----------------------------------------------------------------
    CREATE OR REPLACE VIEW V_MASTER_ANALYTICS AS
    SELECT
        -- 1. KEYS
        f.OUTCOME_ID,
        f.SURVEY_ID,
        f.COMPANY_ID,
        -- 2. MEASURES (Now includes Adherence)
        f.IMPROVEMENT_SCORE,
        f.PHQ9_SCORE,
        f.GAD7_SCORE,
        f.WORK_PRODUCTIVITY_SCORE,
        f.LIFE_SATISFACTION_SCORE,
        f.MEDICATION_ADHERENCE,         -- NEW
        f.SYMPTOM_SEVERITY,             -- NEW
        f.RECOMMEND_TREATMENT,          -- NEW
        f.THERAPY_ATTENDANCE_RATE,
        f.TREATMENT_DURATION_MONTHS,
        f.SESSIONS_COMPLETED,
        -- 3. RESPONDENT DETAILS
        r.AGE, r.GENDER, r.COUNTRY, r.STATE,
        r.INCOME_LEVEL, r.EDUCATION_LEVEL, r.MARITAL_STATUS, r.EMPLOYMENT_STATUS,
        r.YEARS_IN_FIELD, r.HOUSEHOLD_SIZE, r.HAS_CHILDREN,
        r.URBAN_RURAL, r.HEALTH_INSURANCE_TYPE,
        r.TREATMENT AS IS_TREATED,
        r.WORK_INTERFERE, r.FAMILY_HISTORY,
        r.STIGMA_PERCEPTION_SCORE, r.SUPPORT_NETWORK_SCORE, r.TREATMENT_BARRIER_SCORE,
        r.WORK_IMPACT_SEVERITY, r.BENEFITS_AWARENESS,
        r.ANONYMITY_CONCERN, r.LEAVE_DIFFICULTY,
        r.BENEFITS, r.CARE_OPTIONS, r.WELLNESS_PROGRAM, r.SEEK_HELP,
        r.ANONYMITY, r.LEAVE, r.MENTAL_HEALTH_CONSEQUENCE,
        r.PHYS_HEALTH_CONSEQUENCE, r.COWORKERS, r.SUPERVISOR,
        r.MENTAL_HEALTH_INTERVIEW, r.PHYS_HEALTH_INTERVIEW,
        r.MENTAL_VS_PHYSICAL, r.OBS_CONSEQUENCE,
        -- 4. TREATMENT HISTORY
        dth.DIAGNOSIS, dth.TREATMENT_TYPE, dth.MEDICATION,
        dth.CURRENT_STATUS AS TREATMENT_STATUS, dth.INSURANCE_COVERAGE,
        -- 5. COMPANY DETAILS
        c.COMPANY_NAME, c.TECH_COMPANY, c.EMPLOYEE_COUNT_RANGE,
        c.REMOTE_WORK_POLICY,
        c.MENTAL_HEALTH_BENEFITS AS COMPANY_OFFERS_BENEFITS,
        c.WELLNESS_PROGRAM_AVAILABLE, c.EAP_PROGRAM,
        c.MENTAL_HEALTH_COVERAGE_PCT, c.SICK_LEAVE_DAYS,
        c.FLEXIBLE_HOURS, c.MENTAL_HEALTH_TRAINING,
        c.STIGMA_REDUCTION_PROGRAMS,
        -- 6. TIMELINE
        d_followup.FULLDATE AS FOLLOW_UP_DATE,
        d_followup.YEAR AS FOLLOW_UP_YEAR,
        d_followup.MONTHNAME AS FOLLOW_UP_MONTH,
        d_diag.FULLDATE AS DIAGNOSIS_DATE
    FROM MH_DEV_DB.MH_HARMONIZED.FACT_TREATMENT_OUTCOMES AS f
    JOIN MH_DEV_DB.MH_HARMONIZED.DIM_RESPONDENT AS r
        ON f.SURVEY_ID = r.SURVEY_ID
    JOIN MH_DEV_DB.MH_HARMONIZED.DIM_COMPANY AS c
        ON f.COMPANY_ID = c.COMPANY_ID
    JOIN MH_DEV_DB.MH_HARMONIZED.DIM_TREATMENT_HISTORY AS dth
        ON f.TREATMENTHISTORYKEY = dth.TREATMENT_HISTORY_KEY
    LEFT JOIN MH_DEV_DB.MH_HARMONIZED.DIM_DATE AS d_followup
        ON f.FOLLOWUPDATEKEY = d_followup.DATEKEY
    LEFT JOIN MH_DEV_DB.MH_HARMONIZED.DIM_DATE AS d_diag
        ON f.DIAGNOSISDATEKEY = d_diag.DATEKEY;

    ----------------------------------------------------------------
    -- 2. GLOBAL METRICS VIEW
    ----------------------------------------------------------------
    CREATE OR REPLACE VIEW V_GLOBAL_METRICS AS
    WITH main_metrics AS (
        SELECT
            --5.1
            ROUND(COUNT_IF(IS_TREATED = TRUE) / COUNT(*) * 100, 1) AS Treatment_Prevalence_Rate,
            ROUND((COUNT_IF(WORK_INTERFERE != ''Never'' AND IS_TREATED = FALSE) * 100.0)
                  / NULLIF(COUNT_IF(WORK_INTERFERE != ''Never''),0),1) AS Treatment_Gap_Rate,
            ROUND((COUNT_IF(BENEFITS_AWARENESS = 1) * 100.0) / NULLIF(COUNT(*), 0),2) AS Benefits_Awareness_Rate,
            ROUND(AVG(STIGMA_PERCEPTION_SCORE),2) AS Stigma_Perception_Score,
            ROUND((COUNT_IF(SEEK_HELP = ''Yes'') * 100.0) / NULLIF(COUNT(*), 0),2) AS Help_Seeking_Willingness_Rate,
            --5.2
            ROUND(AVG(THERAPY_ATTENDANCE_RATE),2) AS Therapy_Attendance_Rate,
            ROUND(COUNT(CASE WHEN TREATMENT_STATUS ILIKE ''Completed'' THEN 1 END) * 100.0 / COUNT(*), 2) AS Completion_Rate_Percentage,
            ROUND(AVG(IMPROVEMENT_SCORE),2) AS Average_Improvement_Score,
            ROUND(AVG(
                CASE WHEN MEDICATION_ADHERENCE ILIKE ''High'' THEN 100
                     WHEN MEDICATION_ADHERENCE ILIKE ''Medium'' THEN 50
                     ELSE 0
                END
            ), 2) AS Medication_Adherence_Score,
            --5.3--
            ROUND((COUNT(CASE WHEN WORK_INTERFERE IN (''Sometimes'',''Often'') THEN 1 END)
                  / NULLIF(COUNT(SURVEY_ID), 0)) * 100, 2) AS Work_Interference_Rate,
            ROUND(AVG(SUPPORT_NETWORK_SCORE),2) AS Average_support_score,
            ROUND(COUNT(DISTINCT CASE WHEN COMPANY_OFFERS_BENEFITS = TRUE THEN COMPANY_NAME END)
                  / NULLIF(COUNT(DISTINCT COMPANY_NAME), 0) * 100, 2) AS Benefits_Coverage_Rate,
            ROUND(COUNT(DISTINCT CASE WHEN WELLNESS_PROGRAM_AVAILABLE = TRUE THEN COMPANY_NAME END)
                  / NULLIF(COUNT(DISTINCT COMPANY_NAME), 0) * 100, 2) AS Wellness_Program_Availability_Rate,
            ROUND(COUNT(DISTINCT CASE WHEN EAP_PROGRAM = ''Yes'' THEN COMPANY_NAME END)
                  / NULLIF(COUNT(DISTINCT COMPANY_NAME), 0) * 100, 2) AS EAP_Program_Coverage_Rate,
            ROUND(AVG(MENTAL_HEALTH_COVERAGE_PCT), 2) AS Average_Mental_Health_Coverage_Percentage,
            ROUND(AVG(WORK_PRODUCTIVITY_SCORE), 2) AS Average_Work_Productivity_Score,
            --5.4.2
            ROUND(100.0 *
                  COUNT(CASE
                        WHEN COALESCE(NULLIF(LOWER(TRIM(HEALTH_INSURANCE_TYPE)), ''''), ''none'') <> ''none''
                        THEN 1 END)
                  / NULLIF(COUNT(*), 0), 2) AS insurance_coverage_rate_pct,
            --5.5
            ROUND(AVG(TREATMENT_BARRIER_SCORE), 2) AS Average_Treatment_Barrier_Score,
            ROUND(COUNT(CASE WHEN ANONYMITY_CONCERN = 2 THEN 1 END) * 100.0 / COUNT(*), 2) AS Anonymity_Concern_Percentage,
            ROUND(COUNT(CASE WHEN LEAVE_DIFFICULTY >= 2 THEN 1 END) * 100.0 / COUNT(*), 2) AS Leave_Difficulty_Percentage,
            ROUND(COUNT(CASE WHEN SUPERVISOR ILIKE ''Yes'' THEN 1 END) * 100.0 / COUNT(*), 2) AS Supervisor_Percentage,
            ROUND(COUNT(CASE WHEN COWORKERS ILIKE ''Yes'' THEN 1 END) * 100.0 / COUNT(*), 2) AS Coworker_Support_Rate,
            --5.6--
            ROUND(AVG(NULLIF(LIFE_SATISFACTION_SCORE, 0)) , 2) AS Life_Satisfaction_Avg,
            ROUND(COUNT_IF(SYMPTOM_SEVERITY = ''Mild'') / NULLIF(COUNT(SYMPTOM_SEVERITY), 0),2) * 100 AS Symptom_Severity_Mild_Rate,
            ROUND(COUNT_IF(RECOMMEND_TREATMENT = ''Yes'') / COUNT(*),2) * 100 AS Treatment_Recommendation_Rate,
            ROUND(AVG(NULLIF(TREATMENT_DURATION_MONTHS, 0)) , 2) AS Average_Treatment_Duration_Months,
            ROUND(AVG(NULLIF(SESSIONS_COMPLETED, 0)), 2) AS Average_Sessions_Completed,
            --5.7.1
            ROUND(AVG(CASE WHEN IS_TREATED = TRUE THEN 1.0 ELSE 0.0 END) * 0.3, 2) +
            ROUND((AVG(IMPROVEMENT_SCORE) / 100) * 0.4, 2) +
            ROUND((AVG(SUPPORT_NETWORK_SCORE) / 4) * 0.3, 2) AS Mental_Health_Wellness_Index,
            --5.7.2
            ROUND(AVG(IMPROVEMENT_SCORE)
                  / (1 - AVG(CASE WHEN INSURANCE_COVERAGE = ''No'' THEN 1.0 ELSE 0.0 END)), 2) AS Treatment_ROI_Score,
            --6.1
            ROUND((COUNT_IF(WORK_IMPACT_SEVERITY >= 3 OR PHQ9_SCORE >= 15 OR GAD7_SCORE >= 10) * 100.0)
                  / NULLIF(COUNT(*), 0), 2) AS High_Risk_Population_Rate,
            --6.2
            ROUND((COUNT_IF(WORK_IMPACT_SEVERITY = 1 AND IMPROVEMENT_SCORE >= 50) * 100.0)
                  / NULLIF(COUNT_IF(WORK_IMPACT_SEVERITY = 1), 0), 2) AS Early_Intervention_Effectiveness,
            --7.4
            ROUND(AVG(LIFE_SATISFACTION_SCORE), 2) AS Life_Satisfaction_Score,
            --7.5
            ROUND((COUNT_IF(WORK_IMPACT_SEVERITY IN (3,2) AND IMPROVEMENT_SCORE >= 50) * 100.0)
                  / NULLIF(COUNT_IF(WORK_IMPACT_SEVERITY IN (3,2)), 0), 2) AS Symptom_Severity_Reduction_Rate,
            --7.7
            ROUND(AVG(TREATMENT_DURATION_MONTHS), 2) AS Average_Treatment_Duration
        FROM V_MASTER_ANALYTICS
    ),
    country_rates AS (
        SELECT
            COUNTRY,
            1.0 * COUNT_IF(IS_TREATED) / COUNT(*) AS treatment_rate
        FROM V_MASTER_ANALYTICS
        GROUP BY COUNTRY
    ),
    geographic_disparity AS (
        SELECT ROUND((STDDEV_POP(treatment_rate) / NULLIF(AVG(treatment_rate), 0)) * 100, 2) AS geographic_disparity_index
        FROM country_rates
    )
    SELECT *
    FROM main_metrics
    CROSS JOIN geographic_disparity;

    ----------------------------------------------------------------
    -- 4. COMPANY METRICS VIEW
    ----------------------------------------------------------------
    CREATE OR REPLACE VIEW V_COMPANY_METRICS AS
    SELECT
        COMPANY_NAME,
        ROUND(MAX(CASE WHEN COMPANY_OFFERS_BENEFITS = TRUE THEN 1.0 ELSE 0.0 END) * 0.25, 2) +
        ROUND(MAX(CASE WHEN WELLNESS_PROGRAM_AVAILABLE = TRUE THEN 1.0 ELSE 0.0 END) * 0.25,2) +
        ROUND((AVG(SUPPORT_NETWORK_SCORE) / 4.0) * 0.25, 2) +
        ROUND((1.0 - (COUNT_IF(WORK_INTERFERE IN (''Often'', ''Sometimes'')) / COUNT(*))) * 0.25, 2)
            AS Workplace_Mental_Health_Score
    FROM V_MASTER_ANALYTICS
    GROUP BY COMPANY_NAME
    ORDER BY Workplace_Mental_Health_Score DESC;

    RETURN ''SP_LOAD_CONSUMPTION completed successfully'';
END;
';



CALL MH_DEV_DB.MH_CONSUMPTION.SP_LOAD_CONSUMPTION();
