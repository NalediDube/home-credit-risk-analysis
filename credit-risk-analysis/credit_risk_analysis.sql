
USE HomeCredit;
GO

SELECT COUNT(*) AS TotalApplicants
FROM dbo.application_train;
GO

SELECT TOP 5 *
FROM dbo.application_train;
GO
SELECT
    TARGET,
    COUNT(*) AS ApplicantCount,
    CAST(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER ()
        AS DECIMAL(5,2)
    ) AS Percentage
FROM dbo.application_train
GROUP BY TARGET
ORDER BY TARGET;


SELECT
    TARGET,
    COUNT(*) AS ApplicantCount,
    AVG(TRY_CONVERT(FLOAT, AMT_INCOME_TOTAL)) AS AverageIncome,
    AVG(TRY_CONVERT(FLOAT, AMT_CREDIT)) AS AverageCredit,
    AVG(TRY_CONVERT(FLOAT, AMT_ANNUITY)) AS AverageAnnuity
FROM dbo.application_train
GROUP BY TARGET
ORDER BY TARGET;


SELECT
    CASE
        WHEN TRY_CONVERT(FLOAT, AMT_INCOME_TOTAL) IS NULL
          OR TRY_CONVERT(FLOAT, AMT_INCOME_TOTAL) <= 0
            THEN 'Invalid or Missing Income'
        WHEN TRY_CONVERT(FLOAT, AMT_CREDIT) /
             TRY_CONVERT(FLOAT, AMT_INCOME_TOTAL) < 2
            THEN 'Below 2x Income'
        WHEN TRY_CONVERT(FLOAT, AMT_CREDIT) /
             TRY_CONVERT(FLOAT, AMT_INCOME_TOTAL) < 5
            THEN '2x to 5x Income'
        ELSE '5x or More Income'
    END AS CreditToIncomeBand,

    COUNT(*) AS ApplicantCount,

    SUM(CASE WHEN TARGET = 1 THEN 1 ELSE 0 END)
        AS DefaultCount,

    CAST(
        100.0 * SUM(CASE WHEN TARGET = 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(6,2)
    ) AS DefaultRatePct

FROM dbo.application_train
GROUP BY
    CASE
        WHEN TRY_CONVERT(FLOAT, AMT_INCOME_TOTAL) IS NULL
          OR TRY_CONVERT(FLOAT, AMT_INCOME_TOTAL) <= 0
            THEN 'Invalid or Missing Income'
        WHEN TRY_CONVERT(FLOAT, AMT_CREDIT) /
             TRY_CONVERT(FLOAT, AMT_INCOME_TOTAL) < 2
            THEN 'Below 2x Income'
        WHEN TRY_CONVERT(FLOAT, AMT_CREDIT) /
             TRY_CONVERT(FLOAT, AMT_INCOME_TOTAL) < 5
            THEN '2x to 5x Income'
        ELSE '5x or More Income'
    END
ORDER BY CreditToIncomeBand;


WITH ApplicantIncome AS (
    SELECT
        TARGET,
        TRY_CONVERT(FLOAT, AMT_INCOME_TOTAL) AS AnnualIncome
    FROM dbo.application_train
),
IncomeBands AS (
    SELECT
        TARGET,
        CASE
            WHEN AnnualIncome IS NULL OR AnnualIncome <= 0
                THEN 'Missing or Invalid'
            WHEN AnnualIncome < 100000
                THEN 'Below 100k'
            WHEN AnnualIncome < 200000
                THEN '100k to 200k'
            WHEN AnnualIncome < 500000
                THEN '200k to 500k'
            ELSE '500k or More'
        END AS IncomeBand
    FROM ApplicantIncome
)
SELECT
    IncomeBand,
    COUNT(*) AS ApplicantCount,
    SUM(CASE WHEN TARGET = 1 THEN 1 ELSE 0 END)
        AS DefaultCount,
    CAST(
        100.0 * SUM(CASE WHEN TARGET = 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(6,2)
    ) AS DefaultRatePct
FROM IncomeBands
GROUP BY IncomeBand
ORDER BY
    CASE IncomeBand
        WHEN 'Missing or Invalid' THEN 1
        WHEN 'Below 100k' THEN 2
        WHEN '100k to 200k' THEN 3
        WHEN '200k to 500k' THEN 4
        WHEN '500k or More' THEN 5
    END;


	
WITH EmploymentAnalysis AS (
    SELECT
        TARGET,
        TRY_CONVERT(FLOAT, DAYS_EMPLOYED) AS DaysEmployed
    FROM dbo.application_train
),
EmploymentBands AS (
    SELECT
        TARGET,
        CASE
            WHEN DaysEmployed IS NULL
                THEN 'Missing'
            WHEN DaysEmployed = 365243
                THEN 'Not Currently Employed / Special Code'
            WHEN DaysEmployed >= 0
                THEN 'Other / Unclassified'
            WHEN ABS(DaysEmployed) < 365
                THEN 'Less than 1 year'
            WHEN ABS(DaysEmployed) < 1825
                THEN '1 to 5 years'
            WHEN ABS(DaysEmployed) < 3650
                THEN '5 to 10 years'
            ELSE 'More than 10 years'
        END AS EmploymentBand
    FROM EmploymentAnalysis
)
SELECT
    EmploymentBand,
    COUNT(*) AS ApplicantCount,
    SUM(CASE WHEN TARGET = 1 THEN 1 ELSE 0 END)
        AS DefaultCount,
    CAST(
        100.0 * SUM(CASE WHEN TARGET = 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(6,2)
    ) AS DefaultRatePct
FROM EmploymentBands
GROUP BY EmploymentBand
ORDER BY
    CASE EmploymentBand
        WHEN 'Less than 1 year' THEN 1
        WHEN '1 to 5 years' THEN 2
        WHEN '5 to 10 years' THEN 3
        WHEN 'More than 10 years' THEN 4
        WHEN 'Not Currently Employed / Special Code' THEN 5
        WHEN 'Other / Unclassified' THEN 6
        WHEN 'Missing' THEN 7
    END;

	
SELECT
    NAME_CONTRACT_TYPE AS LoanType,
    COUNT(*) AS ApplicantCount,
    SUM(CASE WHEN TARGET = 1 THEN 1 ELSE 0 END)
        AS DefaultCount,
    CAST(
        100.0 * SUM(CASE WHEN TARGET = 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(6,2)
    ) AS DefaultRatePct,
    CAST(
        AVG(TRY_CONVERT(FLOAT, AMT_CREDIT))
        AS DECIMAL(18,2)
    ) AS AverageCreditAmount,
    CAST(
        AVG(TRY_CONVERT(FLOAT, AMT_ANNUITY))
        AS DECIMAL(18,2)
    ) AS AverageAnnuity
FROM dbo.application_train
GROUP BY NAME_CONTRACT_TYPE
ORDER BY DefaultRatePct DESC;


WITH ApplicantAge AS (
    SELECT
        TARGET,
        TRY_CONVERT(FLOAT, DAYS_BIRTH) AS DaysBirth
    FROM dbo.application_train
),
AgeBands AS (
    SELECT
        TARGET,
        CASE
            WHEN DaysBirth IS NULL OR DaysBirth >= 0
                THEN 'Missing or Invalid'
            WHEN ABS(DaysBirth) / 365.25 < 25
                THEN 'Under 25'
            WHEN ABS(DaysBirth) / 365.25 < 35
                THEN '25 to 34'
            WHEN ABS(DaysBirth) / 365.25 < 45
                THEN '35 to 44'
            WHEN ABS(DaysBirth) / 365.25 < 55
                THEN '45 to 54'
            ELSE '55 and Over'
        END AS AgeBand
    FROM ApplicantAge
)
SELECT
    AgeBand,
    COUNT(*) AS ApplicantCount,
    SUM(CASE WHEN TARGET = 1 THEN 1 ELSE 0 END)
        AS DefaultCount,
    CAST(
        100.0 * SUM(CASE WHEN TARGET = 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(6,2)
    ) AS DefaultRatePct
FROM AgeBands
GROUP BY AgeBand
ORDER BY
    CASE AgeBand
        WHEN 'Missing or Invalid' THEN 1
        WHEN 'Under 25' THEN 2
        WHEN '25 to 34' THEN 3
        WHEN '35 to 44' THEN 4
        WHEN '45 to 54' THEN 5
        WHEN '55 and Over' THEN 6
    END;

	
SELECT
    NAME_INCOME_TYPE AS IncomeSource,
    COUNT(*) AS ApplicantCount,
    SUM(CASE WHEN TARGET = 1 THEN 1 ELSE 0 END)
        AS DefaultCount,
    CAST(
        100.0 * SUM(CASE WHEN TARGET = 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(6,2)
    ) AS DefaultRatePct,
    CAST(
        AVG(TRY_CONVERT(FLOAT, AMT_INCOME_TOTAL))
        AS DECIMAL(18,2)
    ) AS AverageIncome
FROM dbo.application_train
GROUP BY NAME_INCOME_TYPE
ORDER BY DefaultRatePct DESC;


WITH ApplicantBurden AS (
    SELECT
        TARGET,
        TRY_CONVERT(FLOAT, AMT_INCOME_TOTAL) AS AnnualIncome,
        TRY_CONVERT(FLOAT, AMT_ANNUITY) AS AnnualAnnuity
    FROM dbo.application_train
),
BurdenBands AS (
    SELECT
        TARGET,
        CASE
            WHEN AnnualIncome IS NULL
              OR AnnualIncome <= 0
              OR AnnualAnnuity IS NULL
              OR AnnualAnnuity < 0
                THEN 'Missing or Invalid'
            WHEN AnnualAnnuity / AnnualIncome < 0.10
                THEN 'Below 10%'
            WHEN AnnualAnnuity / AnnualIncome < 0.20
                THEN '10% to 20%'
            WHEN AnnualAnnuity / AnnualIncome < 0.30
                THEN '20% to 30%'
            ELSE '30% or More'
        END AS PaymentBurdenBand
    FROM ApplicantBurden
)
SELECT
    PaymentBurdenBand,
    COUNT(*) AS ApplicantCount,
    SUM(CASE WHEN TARGET = 1 THEN 1 ELSE 0 END)
        AS DefaultCount,
    CAST(
        100.0 * SUM(CASE WHEN TARGET = 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(6,2)
    ) AS DefaultRatePct
FROM BurdenBands
GROUP BY PaymentBurdenBand
ORDER BY
    CASE PaymentBurdenBand
        WHEN 'Below 10%' THEN 1
        WHEN '10% to 20%' THEN 2
        WHEN '20% to 30%' THEN 3
        WHEN '30% or More' THEN 4
        WHEN 'Missing or Invalid' THEN 5
    END;

	
SELECT
    OCCUPATION_TYPE AS Occupation,
    COUNT(*) AS ApplicantCount,
    SUM(CASE WHEN TARGET = 1 THEN 1 ELSE 0 END)
        AS DefaultCount,
    CAST(
        100.0 * SUM(CASE WHEN TARGET = 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(6,2)
    ) AS DefaultRatePct
FROM dbo.application_train
GROUP BY OCCUPATION_TYPE
ORDER BY DefaultRatePct DESC;

 
WITH IncomeSourceRisk AS (
    SELECT
        NAME_INCOME_TYPE AS IncomeSource,
        COUNT(*) AS ApplicantCount,
        SUM(CASE WHEN TARGET = 1 THEN 1 ELSE 0 END)
            AS DefaultCount
    FROM dbo.application_train
    GROUP BY NAME_INCOME_TYPE
)
SELECT
    IncomeSource,
    ApplicantCount,
    DefaultCount,
    CAST(
        100.0 * DefaultCount /
        NULLIF(SUM(DefaultCount) OVER (), 0)
        AS DECIMAL(6,2)
    ) AS ShareOfAllDefaultsPct,
    CAST(
        100.0 * DefaultCount /
        NULLIF(ApplicantCount, 0)
        AS DECIMAL(6,2)
    ) AS DefaultRatePct
FROM IncomeSourceRisk
ORDER BY DefaultCount DESC;


SELECT
    NAME_INCOME_TYPE AS IncomeSource,
    COUNT(*) AS ApplicantCount,
    SUM(CASE WHEN TARGET = 1 THEN 1 ELSE 0 END)
        AS DefaultCount,
    CAST(
        100.0 * SUM(CASE WHEN TARGET = 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(6,2)
    ) AS DefaultRatePct,
    CAST(
        AVG(TRY_CONVERT(FLOAT, AMT_CREDIT))
        AS DECIMAL(18,2)
    ) AS AverageCreditAmount,
    CAST(
        SUM(
            CASE WHEN TARGET = 1
                 THEN TRY_CONVERT(FLOAT, AMT_CREDIT)
                 ELSE 0
            END
        )
        AS DECIMAL(20,2)
    ) AS CreditAmountForDefaultingApplicants
FROM dbo.application_train
GROUP BY NAME_INCOME_TYPE
ORDER BY CreditAmountForDefaultingApplicants DESC;

WITH ScoreBands AS (
    SELECT
        CASE
            WHEN TRY_CONVERT(FLOAT, EXT_SOURCE_3) IS NULL
                THEN 'Missing / Invalid'
            WHEN TRY_CONVERT(FLOAT, EXT_SOURCE_3) < 0.2
                THEN '1. Below 0.2'
            WHEN TRY_CONVERT(FLOAT, EXT_SOURCE_3) < 0.4
                THEN '2. 0.2 to below 0.4'
            WHEN TRY_CONVERT(FLOAT, EXT_SOURCE_3) < 0.6
                THEN '3. 0.4 to below 0.6'
            WHEN TRY_CONVERT(FLOAT, EXT_SOURCE_3) < 0.8
                THEN '4. 0.6 to below 0.8'
            ELSE '5. 0.8 to 1.0'
        END AS CreditScoreBand,
        TARGET
    FROM dbo.application_train
)
SELECT
    CreditScoreBand,
    COUNT(*) AS ApplicantCount,
    SUM(CASE WHEN TARGET = 1 THEN 1 ELSE 0 END) AS DefaultCount,
    CAST(
        100.0 * SUM(CASE WHEN TARGET = 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(6,2)
    ) AS DefaultRatePct
FROM ScoreBands
GROUP BY CreditScoreBand
ORDER BY CreditScoreBand;


USE HomeCredit;
SET NOCOUNT ON;

DECLARE @TableName NVARCHAR(256) = N'dbo.application_train';

IF OBJECT_ID(@TableName, 'U') IS NULL
BEGIN
    RAISERROR('dbo.application_train was not found in HomeCredit.', 16, 1);
    RETURN;
END;

PRINT '01 - PORTFOLIO SIZE AND TARGET VALIDATION';

SELECT
    COUNT_BIG(*) AS TotalRows,
    SUM(CASE WHEN TARGET = 0 THEN 1 ELSE 0 END) AS NonDefaults,
    SUM(CASE WHEN TARGET = 1 THEN 1 ELSE 0 END) AS Defaults,
    SUM(CASE WHEN TARGET NOT IN (0,1) OR TARGET IS NULL
        THEN 1 ELSE 0 END) AS InvalidTargetRows,
    CAST(100.0 * SUM(CASE WHEN TARGET = 1 THEN 1 ELSE 0 END)
        / NULLIF(COUNT_BIG(*),0) AS DECIMAL(8,3)) AS OverallDefaultRatePct
FROM dbo.application_train;

PRINT '02 - DEFAULT RATE BY CONTRACT TYPE';

IF COL_LENGTH('dbo.application_train','NAME_CONTRACT_TYPE') IS NOT NULL
SELECT
    NAME_CONTRACT_TYPE AS ContractType,
    COUNT_BIG(*) AS Applicants,
    SUM(CASE WHEN TARGET=1 THEN 1 ELSE 0 END) AS Defaults,
    CAST(100.0*SUM(CASE WHEN TARGET=1 THEN 1 ELSE 0 END)
        /NULLIF(COUNT_BIG(*),0) AS DECIMAL(8,3)) AS DefaultRatePct,
    CAST(AVG(TRY_CONVERT(FLOAT,AMT_CREDIT)) AS DECIMAL(18,2)) AS AvgCredit,
    CAST(AVG(TRY_CONVERT(FLOAT,AMT_ANNUITY)) AS DECIMAL(18,2)) AS AvgAnnuity
FROM dbo.application_train
GROUP BY NAME_CONTRACT_TYPE
ORDER BY DefaultRatePct DESC;
ELSE PRINT 'Skipped: NAME_CONTRACT_TYPE not imported.';

PRINT '03 - CREDIT AMOUNT RELATIVE TO INCOME';

WITH X AS (
    SELECT TARGET,
        TRY_CONVERT(FLOAT,AMT_CREDIT) AS Credit,
        TRY_CONVERT(FLOAT,AMT_INCOME_TOTAL) AS Income
    FROM dbo.application_train
)
SELECT
    CASE
        WHEN Income IS NULL OR Income<=0 OR Credit IS NULL
            THEN 'Missing / invalid'
        WHEN Credit/Income<2 THEN 'Below 2x income'
        WHEN Credit/Income<5 THEN '2x to below 5x'
        ELSE '5x income or more'
    END AS CreditIncomeBand,
    COUNT_BIG(*) AS Applicants,
    SUM(CASE WHEN TARGET=1 THEN 1 ELSE 0 END) AS Defaults,
    CAST(100.0*SUM(CASE WHEN TARGET=1 THEN 1 ELSE 0 END)
        /NULLIF(COUNT_BIG(*),0) AS DECIMAL(8,3)) AS DefaultRatePct,
    CAST(AVG(Credit) AS DECIMAL(18,2)) AS AverageCredit
FROM X
GROUP BY CASE
    WHEN Income IS NULL OR Income<=0 OR Credit IS NULL
        THEN 'Missing / invalid'
    WHEN Credit/Income<2 THEN 'Below 2x income'
    WHEN Credit/Income<5 THEN '2x to below 5x'
    ELSE '5x income or more'
END
ORDER BY CreditIncomeBand;

PRINT '04 - ANNUITY PAYMENT BURDEN';

WITH X AS (
    SELECT TARGET,
        TRY_CONVERT(FLOAT,AMT_ANNUITY) AS Annuity,
        TRY_CONVERT(FLOAT,AMT_INCOME_TOTAL) AS Income
    FROM dbo.application_train
)
SELECT
    CASE
        WHEN Income IS NULL OR Income<=0 OR Annuity IS NULL
            THEN 'Missing / invalid'
        WHEN Annuity/Income<0.10 THEN 'Below 10%'
        WHEN Annuity/Income<0.20 THEN '10% to below 20%'
        WHEN Annuity/Income<0.30 THEN '20% to below 30%'
        ELSE '30% or more'
    END AS PaymentBurdenBand,
    COUNT_BIG(*) AS Applicants,
    SUM(CASE WHEN TARGET=1 THEN 1 ELSE 0 END) AS Defaults,
    CAST(100.0*SUM(CASE WHEN TARGET=1 THEN 1 ELSE 0 END)
        /NULLIF(COUNT_BIG(*),0) AS DECIMAL(8,3)) AS DefaultRatePct
FROM X
GROUP BY CASE
    WHEN Income IS NULL OR Income<=0 OR Annuity IS NULL
        THEN 'Missing / invalid'
    WHEN Annuity/Income<0.10 THEN 'Below 10%'
    WHEN Annuity/Income<0.20 THEN '10% to below 20%'
    WHEN Annuity/Income<0.30 THEN '20% to below 30%'
    ELSE '30% or more'
END
ORDER BY PaymentBurdenBand;

PRINT '05 - AGE BAND';

IF COL_LENGTH('dbo.application_train','DAYS_BIRTH') IS NOT NULL
WITH X AS (
    SELECT TARGET,
        ABS(TRY_CONVERT(FLOAT,DAYS_BIRTH))/365.25 AS AgeYears
    FROM dbo.application_train
)
SELECT
    CASE
        WHEN AgeYears IS NULL THEN 'Missing / invalid'
        WHEN AgeYears<25 THEN 'Under 25'
        WHEN AgeYears<35 THEN '25-34'
        WHEN AgeYears<45 THEN '35-44'
        WHEN AgeYears<55 THEN '45-54'
        WHEN AgeYears<65 THEN '55-64'
        ELSE '65+'
    END AS AgeBand,
    COUNT_BIG(*) AS Applicants,
    SUM(CASE WHEN TARGET=1 THEN 1 ELSE 0 END) AS Defaults,
    CAST(100.0*SUM(CASE WHEN TARGET=1 THEN 1 ELSE 0 END)
        /NULLIF(COUNT_BIG(*),0) AS DECIMAL(8,3)) AS DefaultRatePct
FROM X
GROUP BY CASE
    WHEN AgeYears IS NULL THEN 'Missing / invalid'
    WHEN AgeYears<25 THEN 'Under 25'
    WHEN AgeYears<35 THEN '25-34'
    WHEN AgeYears<45 THEN '35-44'
    WHEN AgeYears<55 THEN '45-54'
    WHEN AgeYears<65 THEN '55-64'
    ELSE '65+'
END
ORDER BY AgeBand;
ELSE PRINT 'Skipped: DAYS_BIRTH not imported.';

PRINT '06 - EMPLOYMENT DURATION';

IF COL_LENGTH('dbo.application_train','DAYS_EMPLOYED') IS NOT NULL
WITH X AS (
    SELECT TARGET,
        TRY_CONVERT(FLOAT,DAYS_EMPLOYED) AS DaysEmployed
    FROM dbo.application_train
)
SELECT
    CASE
        WHEN DaysEmployed IS NULL THEN 'Missing / invalid'
        WHEN DaysEmployed=365243 THEN 'Special code - verify meaning'
        WHEN DaysEmployed>=0 THEN 'Non-negative / verify'
        WHEN ABS(DaysEmployed)/365.25<1 THEN 'Under 1 year'
        WHEN ABS(DaysEmployed)/365.25<5 THEN '1 to below 5 years'
        WHEN ABS(DaysEmployed)/365.25<10 THEN '5 to below 10 years'
        ELSE '10+ years'
    END AS EmploymentBand,
    COUNT_BIG(*) AS Applicants,
    SUM(CASE WHEN TARGET=1 THEN 1 ELSE 0 END) AS Defaults,
    CAST(100.0*SUM(CASE WHEN TARGET=1 THEN 1 ELSE 0 END)
        /NULLIF(COUNT_BIG(*),0) AS DECIMAL(8,3)) AS DefaultRatePct
FROM X
GROUP BY CASE
    WHEN DaysEmployed IS NULL THEN 'Missing / invalid'
    WHEN DaysEmployed=365243 THEN 'Special code - verify meaning'
    WHEN DaysEmployed>=0 THEN 'Non-negative / verify'
    WHEN ABS(DaysEmployed)/365.25<1 THEN 'Under 1 year'
    WHEN ABS(DaysEmployed)/365.25<5 THEN '1 to below 5 years'
    WHEN ABS(DaysEmployed)/365.25<10 THEN '5 to below 10 years'
    ELSE '10+ years'
END
ORDER BY EmploymentBand;
ELSE PRINT 'Skipped: DAYS_EMPLOYED not imported.';

PRINT '07 - INCOME SOURCE';

IF COL_LENGTH('dbo.application_train','NAME_INCOME_TYPE') IS NOT NULL
SELECT
    NAME_INCOME_TYPE AS IncomeSource,
    COUNT_BIG(*) AS Applicants,
    SUM(CASE WHEN TARGET=1 THEN 1 ELSE 0 END) AS Defaults,
    CAST(100.0*SUM(CASE WHEN TARGET=1 THEN 1 ELSE 0 END)
        /NULLIF(COUNT_BIG(*),0) AS DECIMAL(8,3)) AS DefaultRatePct,
    CAST(AVG(TRY_CONVERT(FLOAT,AMT_INCOME_TOTAL))
        AS DECIMAL(18,2)) AS AverageIncome,
    CAST(SUM(CASE WHEN TARGET=1
        THEN TRY_CONVERT(FLOAT,AMT_CREDIT) ELSE 0 END)
        AS DECIMAL(20,2)) AS CreditAmountForDefaults
FROM dbo.application_train
GROUP BY NAME_INCOME_TYPE
ORDER BY DefaultRatePct DESC;
ELSE PRINT 'Skipped: NAME_INCOME_TYPE not imported.';

PRINT '08 - EDUCATION';

IF COL_LENGTH('dbo.application_train','NAME_EDUCATION_TYPE') IS NOT NULL
SELECT
    NAME_EDUCATION_TYPE AS Education,
    COUNT_BIG(*) AS Applicants,
    SUM(CASE WHEN TARGET=1 THEN 1 ELSE 0 END) AS Defaults,
    CAST(100.0*SUM(CASE WHEN TARGET=1 THEN 1 ELSE 0 END)
        /NULLIF(COUNT_BIG(*),0) AS DECIMAL(8,3)) AS DefaultRatePct
FROM dbo.application_train
GROUP BY NAME_EDUCATION_TYPE
ORDER BY DefaultRatePct DESC;
ELSE PRINT 'Skipped: NAME_EDUCATION_TYPE not imported.';

PRINT '09 - GENDER';

IF COL_LENGTH('dbo.application_train','CODE_GENDER') IS NOT NULL
SELECT
    CODE_GENDER,
    COUNT_BIG(*) AS Applicants,
    SUM(CASE WHEN TARGET=1 THEN 1 ELSE 0 END) AS Defaults,
    CAST(100.0*SUM(CASE WHEN TARGET=1 THEN 1 ELSE 0 END)
        /NULLIF(COUNT_BIG(*),0) AS DECIMAL(8,3)) AS DefaultRatePct
FROM dbo.application_train
GROUP BY CODE_GENDER
ORDER BY DefaultRatePct DESC;
ELSE PRINT 'Skipped: CODE_GENDER not imported.';

PRINT '10 - FAMILY STATUS';

IF COL_LENGTH('dbo.application_train','NAME_FAMILY_STATUS') IS NOT NULL
SELECT
    NAME_FAMILY_STATUS,
    COUNT_BIG(*) AS Applicants,
    SUM(CASE WHEN TARGET=1 THEN 1 ELSE 0 END) AS Defaults,
    CAST(100.0*SUM(CASE WHEN TARGET=1 THEN 1 ELSE 0 END)
        /NULLIF(COUNT_BIG(*),0) AS DECIMAL(8,3)) AS DefaultRatePct
FROM dbo.application_train
GROUP BY NAME_FAMILY_STATUS
ORDER BY DefaultRatePct DESC;
ELSE PRINT 'Skipped: NAME_FAMILY_STATUS not imported.';

PRINT '11 - CHILDREN';

IF COL_LENGTH('dbo.application_train','CNT_CHILDREN') IS NOT NULL
SELECT
    CASE
        WHEN TRY_CONVERT(INT,CNT_CHILDREN) IS NULL THEN 'Missing / invalid'
        WHEN TRY_CONVERT(INT,CNT_CHILDREN)=0 THEN '0'
        WHEN TRY_CONVERT(INT,CNT_CHILDREN)=1 THEN '1'
        WHEN TRY_CONVERT(INT,CNT_CHILDREN)=2 THEN '2'
        ELSE '3+'
    END AS ChildrenBand,
    COUNT_BIG(*) AS Applicants,
    SUM(CASE WHEN TARGET=1 THEN 1 ELSE 0 END) AS Defaults,
    CAST(100.0*SUM(CASE WHEN TARGET=1 THEN 1 ELSE 0 END)
        /NULLIF(COUNT_BIG(*),0) AS DECIMAL(8,3)) AS DefaultRatePct
FROM dbo.application_train
GROUP BY CASE
    WHEN TRY_CONVERT(INT,CNT_CHILDREN) IS NULL THEN 'Missing / invalid'
    WHEN TRY_CONVERT(INT,CNT_CHILDREN)=0 THEN '0'
    WHEN TRY_CONVERT(INT,CNT_CHILDREN)=1 THEN '1'
    WHEN TRY_CONVERT(INT,CNT_CHILDREN)=2 THEN '2'
    ELSE '3+'
END
ORDER BY ChildrenBand;
ELSE PRINT 'Skipped: CNT_CHILDREN not imported.';

PRINT '12 - CAR AND PROPERTY OWNERSHIP';

IF COL_LENGTH('dbo.application_train','FLAG_OWN_CAR') IS NOT NULL
AND COL_LENGTH('dbo.application_train','FLAG_OWN_REALTY') IS NOT NULL
SELECT
    FLAG_OWN_CAR AS OwnsCar,
    FLAG_OWN_REALTY AS OwnsProperty,
    COUNT_BIG(*) AS Applicants,
    SUM(CASE WHEN TARGET=1 THEN 1 ELSE 0 END) AS Defaults,
    CAST(100.0*SUM(CASE WHEN TARGET=1 THEN 1 ELSE 0 END)
        /NULLIF(COUNT_BIG(*),0) AS DECIMAL(8,3)) AS DefaultRatePct
FROM dbo.application_train
GROUP BY FLAG_OWN_CAR,FLAG_OWN_REALTY
ORDER BY DefaultRatePct DESC;
ELSE PRINT 'Skipped: ownership fields not imported.';

PRINT '13 - HOUSING TYPE';

IF COL_LENGTH('dbo.application_train','NAME_HOUSING_TYPE') IS NOT NULL
SELECT
    NAME_HOUSING_TYPE AS HousingType,
    COUNT_BIG(*) AS Applicants,
    SUM(CASE WHEN TARGET=1 THEN 1 ELSE 0 END) AS Defaults,
    CAST(100.0*SUM(CASE WHEN TARGET=1 THEN 1 ELSE 0 END)
        /NULLIF(COUNT_BIG(*),0) AS DECIMAL(8,3)) AS DefaultRatePct
FROM dbo.application_train
GROUP BY NAME_HOUSING_TYPE
ORDER BY DefaultRatePct DESC;
ELSE PRINT 'Skipped: NAME_HOUSING_TYPE not imported.';

PRINT '14 - ORGANISATION TYPE: LARGEST DEFAULT COUNTS';

IF COL_LENGTH('dbo.application_train','ORGANIZATION_TYPE') IS NOT NULL
SELECT TOP (20)
    ORGANIZATION_TYPE,
    COUNT_BIG(*) AS Applicants,
    SUM(CASE WHEN TARGET=1 THEN 1 ELSE 0 END) AS Defaults,
    CAST(100.0*SUM(CASE WHEN TARGET=1 THEN 1 ELSE 0 END)
        /NULLIF(COUNT_BIG(*),0) AS DECIMAL(8,3)) AS DefaultRatePct
FROM dbo.application_train
GROUP BY ORGANIZATION_TYPE
ORDER BY Defaults DESC;
ELSE PRINT 'Skipped: ORGANIZATION_TYPE not imported.';

PRINT '15 - EXTERNAL SCORES 1, 2 AND 3: SCORE BANDS';

DECLARE @ScoreColumn SYSNAME;
DECLARE @SQL NVARCHAR(MAX);

DECLARE ScoreCursor CURSOR LOCAL FAST_FORWARD FOR
SELECT ColumnName
FROM (VALUES
    ('EXT_SOURCE_1'),('EXT_SOURCE_2'),('EXT_SOURCE_3')
) V(ColumnName)
WHERE COL_LENGTH('dbo.application_train',ColumnName) IS NOT NULL;

OPEN ScoreCursor;
FETCH NEXT FROM ScoreCursor INTO @ScoreColumn;

WHILE @@FETCH_STATUS=0
BEGIN
    SET @SQL = N'
    SELECT
        N''' + @ScoreColumn + N''' AS ScoreVariable,
        CASE
            WHEN TRY_CONVERT(FLOAT,' + QUOTENAME(@ScoreColumn) + N') IS NULL
                THEN ''Missing / invalid''
            WHEN TRY_CONVERT(FLOAT,' + QUOTENAME(@ScoreColumn) + N')<0.2
                THEN ''Below 0.2''
            WHEN TRY_CONVERT(FLOAT,' + QUOTENAME(@ScoreColumn) + N')<0.4
                THEN ''0.2 to below 0.4''
            WHEN TRY_CONVERT(FLOAT,' + QUOTENAME(@ScoreColumn) + N')<0.6
                THEN ''0.4 to below 0.6''
            WHEN TRY_CONVERT(FLOAT,' + QUOTENAME(@ScoreColumn) + N')<0.8
                THEN ''0.6 to below 0.8''
            ELSE ''0.8 to 1.0''
        END AS ScoreBand,
        COUNT_BIG(*) AS Applicants,
        SUM(CASE WHEN TARGET=1 THEN 1 ELSE 0 END) AS Defaults,
        CAST(100.0*SUM(CASE WHEN TARGET=1 THEN 1 ELSE 0 END)
            /NULLIF(COUNT_BIG(*),0) AS DECIMAL(8,3)) AS DefaultRatePct
    FROM dbo.application_train
    GROUP BY CASE
            WHEN TRY_CONVERT(FLOAT,' + QUOTENAME(@ScoreColumn) + N') IS NULL
                THEN ''Missing / invalid''
            WHEN TRY_CONVERT(FLOAT,' + QUOTENAME(@ScoreColumn) + N')<0.2
                THEN ''Below 0.2''
            WHEN TRY_CONVERT(FLOAT,' + QUOTENAME(@ScoreColumn) + N')<0.4
                THEN ''0.2 to below 0.4''
            WHEN TRY_CONVERT(FLOAT,' + QUOTENAME(@ScoreColumn) + N')<0.6
                THEN ''0.4 to below 0.6''
            WHEN TRY_CONVERT(FLOAT,' + QUOTENAME(@ScoreColumn) + N')<0.8
                THEN ''0.6 to below 0.8''
            ELSE ''0.8 to 1.0''
        END
    ORDER BY ScoreBand;';
    EXEC sys.sp_executesql @SQL;
    FETCH NEXT FROM ScoreCursor INTO @ScoreColumn;
END;

CLOSE ScoreCursor;
DEALLOCATE ScoreCursor;

PRINT '16 - SCORE AVAILABILITY PATTERNS';

IF COL_LENGTH('dbo.application_train','EXT_SOURCE_1') IS NOT NULL
AND COL_LENGTH('dbo.application_train','EXT_SOURCE_2') IS NOT NULL
AND COL_LENGTH('dbo.application_train','EXT_SOURCE_3') IS NOT NULL
SELECT
    CASE
        WHEN TRY_CONVERT(FLOAT,EXT_SOURCE_1) IS NOT NULL
         AND TRY_CONVERT(FLOAT,EXT_SOURCE_2) IS NOT NULL
         AND TRY_CONVERT(FLOAT,EXT_SOURCE_3) IS NOT NULL
            THEN 'All three available'
        WHEN TRY_CONVERT(FLOAT,EXT_SOURCE_1) IS NULL
         AND TRY_CONVERT(FLOAT,EXT_SOURCE_2) IS NULL
         AND TRY_CONVERT(FLOAT,EXT_SOURCE_3) IS NULL
            THEN 'All three missing / invalid'
        ELSE 'Some missing / invalid'
    END AS ScoreAvailability,
    COUNT_BIG(*) AS Applicants,
    SUM(CASE WHEN TARGET=1 THEN 1 ELSE 0 END) AS Defaults,
    CAST(100.0*SUM(CASE WHEN TARGET=1 THEN 1 ELSE 0 END)
        /NULLIF(COUNT_BIG(*),0) AS DECIMAL(8,3)) AS DefaultRatePct
FROM dbo.application_train
GROUP BY CASE
        WHEN TRY_CONVERT(FLOAT,EXT_SOURCE_1) IS NOT NULL
         AND TRY_CONVERT(FLOAT,EXT_SOURCE_2) IS NOT NULL
         AND TRY_CONVERT(FLOAT,EXT_SOURCE_3) IS NOT NULL
            THEN 'All three available'
        WHEN TRY_CONVERT(FLOAT,EXT_SOURCE_1) IS NULL
         AND TRY_CONVERT(FLOAT,EXT_SOURCE_2) IS NULL
         AND TRY_CONVERT(FLOAT,EXT_SOURCE_3) IS NULL
            THEN 'All three missing / invalid'
        ELSE 'Some missing / invalid'
    END;
ELSE PRINT 'Skipped: one or more external score columns are missing.';

PRINT '17 - EXTERNAL SCORE AND PAYMENT BURDEN INTERACTION';

IF COL_LENGTH('dbo.application_train','EXT_SOURCE_3') IS NOT NULL
SELECT
    CASE
        WHEN TRY_CONVERT(FLOAT,EXT_SOURCE_3) IS NULL THEN 'Missing score'
        WHEN TRY_CONVERT(FLOAT,EXT_SOURCE_3)<0.4 THEN 'Score below 0.4'
        ELSE 'Score 0.4 or higher'
    END AS ScoreGroup,
    CASE
        WHEN TRY_CONVERT(FLOAT,AMT_INCOME_TOTAL) IS NULL
          OR TRY_CONVERT(FLOAT,AMT_INCOME_TOTAL)<=0
          OR TRY_CONVERT(FLOAT,AMT_ANNUITY) IS NULL
            THEN 'Missing / invalid burden'
        WHEN TRY_CONVERT(FLOAT,AMT_ANNUITY)
             /NULLIF(TRY_CONVERT(FLOAT,AMT_INCOME_TOTAL),0)<0.2
            THEN 'Burden below 20%'
        ELSE 'Burden 20% or higher'
    END AS PaymentBurdenGroup,
    COUNT_BIG(*) AS Applicants,
    SUM(CASE WHEN TARGET=1 THEN 1 ELSE 0 END) AS Defaults,
    CAST(100.0*SUM(CASE WHEN TARGET=1 THEN 1 ELSE 0 END)
        /NULLIF(COUNT_BIG(*),0) AS DECIMAL(8,3)) AS DefaultRatePct
FROM dbo.application_train
GROUP BY
    CASE
        WHEN TRY_CONVERT(FLOAT,EXT_SOURCE_3) IS NULL THEN 'Missing score'
        WHEN TRY_CONVERT(FLOAT,EXT_SOURCE_3)<0.4 THEN 'Score below 0.4'
        ELSE 'Score 0.4 or higher'
    END,
    CASE
        WHEN TRY_CONVERT(FLOAT,AMT_INCOME_TOTAL) IS NULL
          OR TRY_CONVERT(FLOAT,AMT_INCOME_TOTAL)<=0
          OR TRY_CONVERT(FLOAT,AMT_ANNUITY) IS NULL
            THEN 'Missing / invalid burden'
        WHEN TRY_CONVERT(FLOAT,AMT_ANNUITY)
             /NULLIF(TRY_CONVERT(FLOAT,AMT_INCOME_TOTAL),0)<0.2
            THEN 'Burden below 20%'
        ELSE 'Burden 20% or higher'
    END
ORDER BY ScoreGroup,PaymentBurdenGroup;
ELSE PRINT 'Skipped: EXT_SOURCE_3 not imported.';

PRINT '18 - CREDIT BUREAU ENQUIRIES';

IF COL_LENGTH('dbo.application_train','AMT_REQ_CREDIT_BUREAU_YEAR') IS NOT NULL
SELECT
    CASE
        WHEN TRY_CONVERT(FLOAT,AMT_REQ_CREDIT_BUREAU_YEAR) IS NULL
            THEN 'Missing / invalid'
        WHEN TRY_CONVERT(FLOAT,AMT_REQ_CREDIT_BUREAU_YEAR)=0
            THEN '0 enquiries'
        WHEN TRY_CONVERT(FLOAT,AMT_REQ_CREDIT_BUREAU_YEAR)=1
            THEN '1 enquiry'
        WHEN TRY_CONVERT(FLOAT,AMT_REQ_CREDIT_BUREAU_YEAR)<=3
            THEN '2-3 enquiries'
        ELSE '4+ enquiries'
    END AS EnquiryBand,
    COUNT_BIG(*) AS Applicants,
    SUM(CASE WHEN TARGET=1 THEN 1 ELSE 0 END) AS Defaults,
    CAST(100.0*SUM(CASE WHEN TARGET=1 THEN 1 ELSE 0 END)
        /NULLIF(COUNT_BIG(*),0) AS DECIMAL(8,3)) AS DefaultRatePct
FROM dbo.application_train
GROUP BY CASE
        WHEN TRY_CONVERT(FLOAT,AMT_REQ_CREDIT_BUREAU_YEAR) IS NULL
            THEN 'Missing / invalid'
        WHEN TRY_CONVERT(FLOAT,AMT_REQ_CREDIT_BUREAU_YEAR)=0
            THEN '0 enquiries'
        WHEN TRY_CONVERT(FLOAT,AMT_REQ_CREDIT_BUREAU_YEAR)=1
            THEN '1 enquiry'
        WHEN TRY_CONVERT(FLOAT,AMT_REQ_CREDIT_BUREAU_YEAR)<=3
            THEN '2-3 enquiries'
        ELSE '4+ enquiries'
    END
ORDER BY EnquiryBand;
ELSE PRINT 'Skipped: credit bureau enquiry field not imported.';

PRINT '19 - MISSINGNESS AND INVALID NUMERIC VALUES';

DECLARE @NumericColumns TABLE (ColumnName SYSNAME);
INSERT INTO @NumericColumns VALUES
('AMT_INCOME_TOTAL'),('AMT_CREDIT'),('AMT_ANNUITY'),
('DAYS_BIRTH'),('DAYS_EMPLOYED'),
('EXT_SOURCE_1'),('EXT_SOURCE_2'),('EXT_SOURCE_3'),
('CNT_CHILDREN'),('DAYS_ID_PUBLISH');

DECLARE @Col SYSNAME;
DECLARE QualityCursor CURSOR LOCAL FAST_FORWARD FOR
SELECT ColumnName FROM @NumericColumns
WHERE COL_LENGTH('dbo.application_train',ColumnName) IS NOT NULL;

OPEN QualityCursor;
FETCH NEXT FROM QualityCursor INTO @Col;

WHILE @@FETCH_STATUS=0
BEGIN
    SET @SQL = N'
    SELECT
        N''' + @Col + N''' AS ColumnName,
        COUNT_BIG(*) AS TotalRows,
        SUM(CASE WHEN ' + QUOTENAME(@Col) + N' IS NULL
            THEN 1 ELSE 0 END) AS ActualNulls,
        SUM(CASE WHEN ' + QUOTENAME(@Col) + N' IS NOT NULL
              AND TRY_CONVERT(FLOAT,' + QUOTENAME(@Col) + N') IS NULL
            THEN 1 ELSE 0 END) AS UnparseableValues,
        CAST(100.0*SUM(CASE WHEN ' + QUOTENAME(@Col) + N' IS NULL
            OR TRY_CONVERT(FLOAT,' + QUOTENAME(@Col) + N') IS NULL
            THEN 1 ELSE 0 END)/NULLIF(COUNT_BIG(*),0)
            AS DECIMAL(8,3)) AS MissingOrUnparseablePct
    FROM dbo.application_train;';
    EXEC sys.sp_executesql @SQL;
    FETCH NEXT FROM QualityCursor INTO @Col;
END;

CLOSE QualityCursor;
DEALLOCATE QualityCursor;

PRINT '20 - NEGATIVE OR NON-POSITIVE FINANCIAL VALUES';

SELECT
    COUNT_BIG(*) AS TotalRows,
    SUM(CASE WHEN TRY_CONVERT(FLOAT,AMT_INCOME_TOTAL)<=0
        THEN 1 ELSE 0 END) AS NonPositiveIncome,
    SUM(CASE WHEN TRY_CONVERT(FLOAT,AMT_CREDIT)<=0
        THEN 1 ELSE 0 END) AS NonPositiveCredit,
    SUM(CASE WHEN TRY_CONVERT(FLOAT,AMT_ANNUITY)<=0
        THEN 1 ELSE 0 END) AS NonPositiveAnnuity,
    SUM(CASE WHEN TRY_CONVERT(FLOAT,AMT_INCOME_TOTAL) IS NULL
        THEN 1 ELSE 0 END) AS MissingOrInvalidIncome,
    SUM(CASE WHEN TRY_CONVERT(FLOAT,AMT_CREDIT) IS NULL
        THEN 1 ELSE 0 END) AS MissingOrInvalidCredit,
    SUM(CASE WHEN TRY_CONVERT(FLOAT,AMT_ANNUITY) IS NULL
        THEN 1 ELSE 0 END) AS MissingOrInvalidAnnuity
FROM dbo.application_train;

PRINT '21 - DUPLICATE APPLICATION IDS, IF AVAILABLE';

IF COL_LENGTH('dbo.application_train','SK_ID_CURR') IS NOT NULL
BEGIN
    EXEC sys.sp_executesql N'
    SELECT
        COUNT_BIG(*) AS RowsWithApplicationID,
        COUNT(DISTINCT SK_ID_CURR) AS DistinctApplicationIDs,
        COUNT_BIG(*)-COUNT(DISTINCT SK_ID_CURR) AS DuplicateIDExcessRows
    FROM dbo.application_train;

    SELECT TOP (20)
        SK_ID_CURR, COUNT_BIG(*) AS RowsPerID
    FROM dbo.application_train
    GROUP BY SK_ID_CURR
    HAVING COUNT_BIG(*)>1
    ORDER BY RowsPerID DESC;';
END
ELSE PRINT 'Skipped: SK_ID_CURR not imported.';

PRINT '22 - CREDIT EXPOSURE ASSOCIATED WITH DEFAULTING APPLICANTS';

SELECT
    COUNT_BIG(*) AS TotalApplicants,
    SUM(CASE WHEN TARGET=1 THEN 1 ELSE 0 END) AS DefaultingApplicants,
    CAST(SUM(CASE WHEN TARGET=1
        THEN TRY_CONVERT(FLOAT,AMT_CREDIT) ELSE 0 END)
        AS DECIMAL(20,2)) AS CreditAmountForDefaultingApplicants,
    CAST(SUM(CASE WHEN TARGET=0
        THEN TRY_CONVERT(FLOAT,AMT_CREDIT) ELSE 0 END)
        AS DECIMAL(20,2)) AS CreditAmountForNonDefaultingApplicants,
    CAST(AVG(CASE WHEN TARGET=1
        THEN TRY_CONVERT(FLOAT,AMT_CREDIT) END)
        AS DECIMAL(18,2)) AS AverageCreditForDefaultingApplicants,
    CAST(AVG(CASE WHEN TARGET=0
        THEN TRY_CONVERT(FLOAT,AMT_CREDIT) END)
        AS DECIMAL(18,2)) AS AverageCreditForNonDefaultingApplicants
FROM dbo.application_train;

PRINT '23 - PORTFOLIO DEFAULT CONCENTRATION BY INCOME SOURCE';

IF COL_LENGTH('dbo.application_train','NAME_INCOME_TYPE') IS NOT NULL
WITH X AS (
    SELECT NAME_INCOME_TYPE,
        COUNT_BIG(*) AS Applicants,
        SUM(CASE WHEN TARGET=1 THEN 1 ELSE 0 END) AS Defaults
    FROM dbo.application_train
    GROUP BY NAME_INCOME_TYPE
),
T AS (
    SELECT SUM(Defaults) AS TotalDefaults FROM X
)
SELECT
    X.NAME_INCOME_TYPE AS IncomeSource,
    X.Applicants,
    X.Defaults,
    CAST(100.0*X.Defaults/NULLIF(X.Applicants,0)
        AS DECIMAL(8,3)) AS DefaultRatePct,
    CAST(100.0*X.Defaults/NULLIF(T.TotalDefaults,0)
        AS DECIMAL(8,3)) AS ShareOfAllDefaultsPct
FROM X CROSS JOIN T
ORDER BY ShareOfAllDefaultsPct DESC;
ELSE PRINT 'Skipped: NAME_INCOME_TYPE not imported.';

PRINT '24 - DATASET SCHEMA: IMPORTED COLUMNS';

SELECT
    ORDINAL_POSITION,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA='dbo'
  AND TABLE_NAME='application_train'
ORDER BY ORDINAL_POSITION;

PRINT '25 - FINAL EXECUTION CHECK';
SELECT
    'SQL analysis pack reached its final section' AS ExecutionStatus,
    COUNT_BIG(*) AS ApplicationRows
FROM dbo.application_train;

PRINT 'IMPORTANT: Review all result sets and any skipped-section messages.';
PRINT 'This script performs analysis only and does not modify the source table.';
