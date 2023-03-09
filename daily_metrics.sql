--- This query returns total number of transactions and total amount wagered on Arcadeum
--- Game contracts: https://arcadeum.gitbook.io/arcadeum/contracts
--- Run this query in Flipside: https://flipsidecrypto.xyz/

SELECT 
  DATE_TRUNC('day', BLOCK_TIMESTAMP) AS block_date,
  COUNT(DISTINCT(TX_HASH)) AS count_transactions,
  COUNT(DISTINCT(ORIGIN_FROM_ADDRESS)) AS unique_wallets_that_wagered,
  SUM(EVENT_INPUTS['value'] / 1e6) AS usd_amount
FROM arbitrum.core.fact_event_logs
WHERE 
  BLOCK_TIMESTAMP >= '2023-02-10 11:28'
  AND EVENT_NAME = 'Transfer'
  AND EVENT_INDEX = 2
  AND LOWER(ORIGIN_TO_ADDRESS) IN (
    LOWER('0xAdC8bD9Ef156BBa378955E11A5cf3de25039546e'), -- GameRoulette
    LOWER('0xc664b8d7e86c48c0162090b545bc49dc9395c50b'), -- GameDice
    LOWER('0xa79EAF9F4ec3e8db9150501f8Ba7dDB5b467880F'), -- GameWheel
    LOWER('0x6b29f1958f2A214f8C44e10C9928db66432201bB'), -- GameSlide
    LOWER('0x01CaCe27d694C278DE190F8B626c4bB2d69a245F'), -- GameLimbo
    LOWER('0x0B82A9b7659Bfa3De5fDB320e55E273051CaE6e9'), -- GameRockPaperScissors
    LOWER('0xA22E051692449Af1E1C21ba17016ac24349C5aa8')  -- GameCoinFlip
)
GROUP BY 1
ORDER BY 1