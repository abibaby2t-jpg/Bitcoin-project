;; GoatBit (GOAT) fungible token for Stacks
;; Minimal SIP-010-like FT with owner-controlled minting and user burn

(define-fungible-token goatbit)

;; Owner is set lazily on the first call to an owner-only function (e.g. mint/set-owner).
(define-data-var owner (optional principal) none)

(define-constant err-unauthorized u100)
(define-constant err-zero-amount u101)

(define-private (ensure-owner)
  (match (var-get owner)
    o (if (is-eq tx-sender o)
          (ok true)
          (err err-unauthorized))
    (begin
      (var-set owner (some tx-sender))
      (ok true))))

;; --- Public entrypoints ---
(define-public (transfer (recipient principal) (amount uint))
  (if (is-eq amount u0)
      (err err-zero-amount)
      (ft-transfer? goatbit amount tx-sender recipient)))

(define-public (mint (recipient principal) (amount uint))
  (begin
    (try! (ensure-owner))
    (if (is-eq amount u0)
        (err err-zero-amount)
        (ft-mint? goatbit amount recipient))))

(define-public (burn (amount uint))
  (if (is-eq amount u0)
      (err err-zero-amount)
      (ft-burn? goatbit amount tx-sender)))

(define-public (set-owner (new-owner principal))
  (begin
    (try! (ensure-owner))
    (var-set owner (some new-owner))
    (ok true)))

;; --- Read-only helpers ---
(define-read-only (get-name) "GoatBit")
(define-read-only (get-symbol) "GOAT")
(define-read-only (get-decimals) u6)
(define-read-only (get-total-supply) (ft-get-supply goatbit))
(define-read-only (get-balance (who principal)) (ft-get-balance goatbit who))
(define-read-only (get-owner) (var-get owner))
