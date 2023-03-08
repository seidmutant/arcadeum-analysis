--- This query returns total number of transactions and total amount wagered on Arcadeum
--- Game contracts: https://arcadeum.gitbook.io/arcadeum/contracts
--- Run this query in Dune: https://dune.com/

SELECT 
    DATE_TRUNC('day', A.block_time) as block_date,
    COUNT(DISTINCT(LOWER(A.`tx_hash`))) AS count_transactions,
    COUNT(DISTINCT(LOWER(B.`from`))) AS count_unqiue_wallets,
    SUM(B.value / 1e18) as eth_amount
FROM arbitrum.logs AS A
JOIN arbitrum.transactions AS B
ON LOWER(A.`tx_hash`) = LOWER(B.`hash`)
WHERE 
    LOWER(A.contract_address) IN (
            LOWER('0xAdC8bD9Ef156BBa378955E11A5cf3de25039546e') -- GameRoulette
            , LOWER('0xC664b8D7E86C48C0162090B545bc49DC9395c50b') -- GameDice
            , LOWER('0xa79EAF9F4ec3e8db9150501f8Ba7dDB5b467880F') -- GameWheel
            , LOWER('0x6b29f1958f2A214f8C44e10C9928db66432201bB') -- GameSlide
            , LOWER('0x01CaCe27d694C278DE190F8B626c4bB2d69a245F') -- GameLimbo
            , LOWER('0x0B82A9b7659Bfa3De5fDB320e55E273051CaE6e9') -- GameRockPaperScissors
            , LOWER('0xA22E051692449Af1E1C21ba17016ac24349C5aa8') -- GameCoinFlip
        )
    AND A.block_time >= '2023-02-10 11:28'
    AND B.block_time >= '2023-02-10 11:28'
GROUP BY 1
ORDER BY 2 DESC