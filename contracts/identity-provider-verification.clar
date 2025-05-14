;; Identity Provider Verification Contract
;; Validates credential issuers in the federation

(define-data-var admin principal tx-sender)

;; Map of verified identity providers
(define-map verified-providers principal {
  name: (string-ascii 64),
  url: (string-ascii 128),
  verification-date: uint,
  status: (string-ascii 16)
})

;; Public function to register a new identity provider (admin only)
(define-public (register-provider
    (provider principal)
    (name (string-ascii 64))
    (url (string-ascii 128)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (not (is-some (map-get? verified-providers provider))) (err u100))
    (ok (map-set verified-providers provider {
      name: name,
      url: url,
      verification-date: block-height,
      status: "active"
    }))
  )
)

;; Public function to verify an identity provider's status
(define-read-only (is-verified-provider (provider principal))
  (if (is-some (map-get? verified-providers provider))
    (let ((provider-data (unwrap-panic (map-get? verified-providers provider))))
      (is-eq (get status provider-data) "active"))
    false
  )
)

;; Public function to get provider details
(define-read-only (get-provider-details (provider principal))
  (map-get? verified-providers provider)
)

;; Public function to update provider status (admin only)
(define-public (update-provider-status
    (provider principal)
    (new-status (string-ascii 16)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-some (map-get? verified-providers provider)) (err u404))
    (ok (map-set verified-providers provider
      (merge (unwrap-panic (map-get? verified-providers provider))
             { status: new-status })))
  )
)

;; Public function to transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (var-set admin new-admin))
  )
)
