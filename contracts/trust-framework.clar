;; Trust Framework Contract
;; Manages relationships between identity systems

(define-data-var admin principal tx-sender)

;; Map of trust relationships between identity systems
(define-map trust-relationships
  { system-a: principal, system-b: principal }
  { trust-level: uint, established-at: uint, metadata: (string-utf8 256) }
)

;; Public function to establish trust between two systems (admin only)
(define-public (establish-trust
    (system-a principal)
    (system-b principal)
    (trust-level uint)
    (metadata (string-utf8 256)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (not (is-eq system-a system-b)) (err u100))
    (ok (map-set trust-relationships
      { system-a: system-a, system-b: system-b }
      { trust-level: trust-level, established-at: block-height, metadata: metadata }
    ))
  )
)

;; Public function to check trust relationship between systems
(define-read-only (get-trust-relationship (system-a principal) (system-b principal))
  (map-get? trust-relationships { system-a: system-a, system-b: system-b })
)

;; Public function to check if two systems trust each other
(define-read-only (systems-trust-each-other (system-a principal) (system-b principal))
  (and
    (is-some (map-get? trust-relationships { system-a: system-a, system-b: system-b }))
    (is-some (map-get? trust-relationships { system-a: system-b, system-b: system-a }))
  )
)

;; Public function to revoke trust between systems (admin only)
(define-public (revoke-trust (system-a principal) (system-b principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-some (map-get? trust-relationships { system-a: system-a, system-b: system-b })) (err u404))
    (ok (map-delete trust-relationships { system-a: system-a, system-b: system-b }))
  )
)

;; Public function to transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (var-set admin new-admin))
  )
)
