;; title: unique-coin-token
;; version: 1.0.0
;; summary: A unique fungible token with special features
;; description: UniCoin (UNI) - A SIP-010 compliant token with minting controls, burn functionality, and unique holder rewards

;; traits
;; For now, we'll implement SIP-010 functions without the trait dependency
;; In production, you would use: (use-trait sip-010-trait 'SP3FBR2AGK5H9QBDH3EEN6DF8EK8JY7RX8QJ5SVTE.sip-010-trait-ft-standard.sip-010-trait)

;; token definitions
(define-fungible-token unicoin)

;; constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-OWNER-ONLY (err u100))
(define-constant ERR-NOT-TOKEN-OWNER (err u101))
(define-constant ERR-INSUFFICIENT-BALANCE (err u102))
(define-constant ERR-INVALID-AMOUNT (err u103))
(define-constant ERR-MINTING-DISABLED (err u104))
(define-constant TOTAL-SUPPLY u1000000000000) ;; 10,000,000 tokens with 6 decimals

;; data vars
(define-data-var token-name (string-ascii 32) "UniCoin")
(define-data-var token-symbol (string-ascii 10) "UNI")
(define-data-var token-uri (optional (string-utf8 256)) none)
(define-data-var token-decimals uint u6)
(define-data-var minting-enabled bool true)
(define-data-var total-minted uint u0)

;; data maps
(define-map holder-rewards principal uint)
(define-map last-reward-claim principal uint)
(define-map authorized-minters principal bool)

;; public functions

;; SIP-010 Standard Functions
(define-public (transfer (amount uint) (from principal) (to principal) (memo (optional (buff 34))))
  (begin
    (asserts! (or (is-eq from tx-sender) (is-eq from contract-caller)) ERR-NOT-TOKEN-OWNER)
    (ft-transfer? unicoin amount from to)
  )
)

(define-public (mint (amount uint) (to principal))
  (begin
    (asserts! (var-get minting-enabled) ERR-MINTING-DISABLED)
    (asserts! (or (is-eq tx-sender CONTRACT-OWNER) 
                  (default-to false (map-get? authorized-minters tx-sender))) ERR-OWNER-ONLY)
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (<= (+ (var-get total-minted) amount) TOTAL-SUPPLY) ERR-INVALID-AMOUNT)
    (try! (ft-mint? unicoin amount to))
    (var-set total-minted (+ (var-get total-minted) amount))
    (ok true)
  )
)

(define-public (burn (amount uint))
  (begin
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (ft-burn? unicoin amount tx-sender)
  )
)

;; Admin Functions
(define-public (set-token-uri (value (optional (string-utf8 256))))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
    (ok (var-set token-uri value))
  )
)

(define-public (toggle-minting)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
    (ok (var-set minting-enabled (not (var-get minting-enabled))))
  )
)

(define-public (add-authorized-minter (minter principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
    (ok (map-set authorized-minters minter true))
  )
)

(define-public (remove-authorized-minter (minter principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
    (ok (map-delete authorized-minters minter))
  )
)

;; Unique Features
(define-public (claim-holder-rewards)
  (let (
    (current-block stacks-block-height)
    (holder-balance (ft-get-balance unicoin tx-sender))
    (last-claim (default-to u0 (map-get? last-reward-claim tx-sender)))
    (blocks-since-claim (- current-block last-claim))
    (reward-amount (/ (* holder-balance blocks-since-claim) u1000000)) ;; 0.0001% per block
  )
    (asserts! (> holder-balance u0) ERR-INSUFFICIENT-BALANCE)
    (asserts! (> blocks-since-claim u144) ERR-INVALID-AMOUNT) ;; At least 1 day (144 blocks)
    (map-set last-reward-claim tx-sender current-block)
    (map-set holder-rewards tx-sender (+ (default-to u0 (map-get? holder-rewards tx-sender)) reward-amount))
    (if (> reward-amount u0)
      (ft-mint? unicoin reward-amount tx-sender)
      (ok true)
    )
  )
)

;; read only functions

;; SIP-010 Standard Read-Only Functions
(define-read-only (get-name)
  (ok (var-get token-name))
)

(define-read-only (get-symbol)
  (ok (var-get token-symbol))
)

(define-read-only (get-decimals)
  (ok (var-get token-decimals))
)

(define-read-only (get-balance (who principal))
  (ok (ft-get-balance unicoin who))
)

(define-read-only (get-total-supply)
  (ok (ft-get-supply unicoin))
)

(define-read-only (get-token-uri)
  (ok (var-get token-uri))
)

;; Additional Read-Only Functions
(define-read-only (get-contract-owner)
  CONTRACT-OWNER
)

(define-read-only (is-minting-enabled)
  (var-get minting-enabled)
)

(define-read-only (get-total-minted)
  (var-get total-minted)
)

(define-read-only (get-remaining-supply)
  (- TOTAL-SUPPLY (var-get total-minted))
)

(define-read-only (is-authorized-minter (minter principal))
  (default-to false (map-get? authorized-minters minter))
)

(define-read-only (get-holder-rewards (holder principal))
  (default-to u0 (map-get? holder-rewards holder))
)

(define-read-only (get-last-reward-claim (holder principal))
  (default-to u0 (map-get? last-reward-claim holder))
)

;; private functions

;; Initialize contract with initial mint to contract owner
(begin
  (try! (ft-mint? unicoin u100000000000 CONTRACT-OWNER)) ;; Mint 100,000 tokens to owner
  (var-set total-minted u100000000000)
)

