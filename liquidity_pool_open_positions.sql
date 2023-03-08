--- QUERY NEEDS TO BE RUN IN FLIPSIDE
--- https://flipsidecrypto.xyz/

WITH event_logs AS (
  SELECT TX_HASH, BLOCK_TIMESTAMP, EVENT_NAME, EVENT_INPUTS, CONTRACT_ADDRESS
  FROM arbitrum.core.fact_event_logs
  WHERE 
    BLOCK_TIMESTAMP >= '2023-02-10 00:00:00.000'
    AND TX_STATUS = 'SUCCESS'
),

event_logs_contract AS (
  SELECT CONTRACT_ADDRESS, TX_HASH, BLOCK_TIMESTAMP, EVENT_NAME, EVENT_INPUTS['amount'] AS AMOUNT
  FROM event_logs
  WHERE 
    CONTRACT_ADDRESS = '0xc0f05732d1cda6f59487ceeef4390abcad86ea3e'
),

event_logs_token AS (
    SELECT 
      TX_HASH,
      EVENT_INPUTS['tokenId'] AS TOKEN_ID
    FROM event_logs
    WHERE EVENT_NAME = 'IncreaseLiquidity'
),

event_transactions AS (
  SELECT
    A.CONTRACT_ADDRESS,
    B.TOKEN_ID,
    A.BLOCK_TIMESTAMP, 
    A.EVENT_NAME, 
    A.AMOUNT
  FROM event_logs_contract AS A 
  JOIN event_logs_token AS B
  ON A.TX_HASH = B.TX_HASH
  WHERE 
    A.BLOCK_TIMESTAMP >= '2023-02-10 00:00:00.000'  
),

mint AS (
  SELECT 
    CONTRACT_ADDRESS, 
    TOKEN_ID, 
    BLOCK_TIMESTAMP, 
    AMOUNT
  FROM event_transactions
  WHERE EVENT_NAME = 'Mint'
),

burn AS (
  SELECT 
    CONTRACT_ADDRESS, 
    TOKEN_ID, 
    BLOCK_TIMESTAMP, 
    -1*AMOUNT
  FROM event_transactions
  WHERE EVENT_NAME = 'Burn'
),

liquidity_pool_combined AS (
  SELECT * FROM mint
  UNION ALL 
  SELECT * FROM burn
),

liquidity_pool_final_snapshot AS (
    SELECT 
        TOKEN_ID, 
        CONTRACT_ADDRESS,
        SUM(AMOUNT) AS total_amount, 
        MIN(BLOCK_TIMESTAMP) AS min_block_time,
        MAX(BLOCK_TIMESTAMP) AS max_block_time
    FROM liquidity_pool_combined
    GROUP BY 1, 2
),

liquidity_pool_total_amount AS (
    SELECT 
        contract_address,
        max_block_time, 
        min_block_time,
        SUM(total_amount) AS total_amount, 
        COUNT(*) AS unique_open_positions
    FROM liquidity_pool_final_snapshot
    GROUP BY 1, 2, 3
),

generate_date_minute AS (
  SELECT DISTINCT DATE_TRUNC('minute', BLOCK_TIMESTAMP) AS date_minute
  FROM event_logs
),

liquidity_pool_total_amount_final AS (
  SELECT
      A.date_minute, 
      DATE_TRUNC('day', A.date_minute) AS block_day,
      contract_address,
      SUM(
          CASE WHEN
              (A.date_minute >= min_block_time AND A.date_minute <= max_block_time AND total_amount = 0) 
              OR (A.date_minute >= min_block_time AND total_amount > 1)
          THEN 1 ELSE 0 END
      ) AS count_open_positions
  FROM generate_date_minute AS A
  CROSS JOIN liquidity_pool_total_amount AS B
  GROUP BY 1, 2, 3
)

SELECT
  block_day, 
  MAX(count_open_positions) AS count_open_positions
FROM liquidity_pool_total_amount_final
GROUP BY 1
ORDER BY 1