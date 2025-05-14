;; Authentication Protocol Contract
;; Manages secure login processes across the federation

(define-data-var admin principal tx-sender)

;; Map of supported authentication protocols
(define-map supported-protocols
  { protocol-id: (string-ascii 32) }
  {
    name: (string-ascii 64),
    version: (string-ascii 16),
    description: (string-utf8 256),
    status: (string-ascii 16)
  }
)

;; Map of system protocol implementations
(define-map system-protocols
  { system: principal, protocol-id: (string-ascii 32) }
  {
    endpoint: (string-ascii 128),
    registered-at: uint,
    last-verified: uint,
    status: (string-ascii 16)
  }
)

;; Public function to register a protocol (admin only)
(define-public (register-protocol
    (protocol-id (string-ascii 32))
    (name (string-ascii 64))
    (version (string-ascii 16))
    (description (string-utf8 256)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (not (is-some (map-get? supported-protocols { protocol-id: protocol-id }))) (err u100))
    (ok (map-set supported-protocols
      { protocol-id: protocol-id }
      {
        name: name,
        version: version,
        description: description,
        status: "active"
      }
    ))
  )
)

;; Public function to register a system's protocol implementation
(define-public (register-system-protocol
    (system principal)
    (protocol-id (string-ascii 32))
    (endpoint (string-ascii 128)))
  (begin
    (asserts! (is-some (map-get? supported-protocols { protocol-id: protocol-id })) (err u404))
    (asserts! (or (is-eq tx-sender (var-get admin)) (is-eq tx-sender system)) (err u403))
    (ok (map-set system-protocols
      { system: system, protocol-id: protocol-id }
      {
        endpoint: endpoint,
        registered-at: block-height,
        last-verified: block-height,
        status: "active"
      }
    ))
  )
)

;; Public function to get protocol details
(define-read-only (get-protocol-details (protocol-id (string-ascii 32)))
  (map-get? supported-protocols { protocol-id: protocol-id })
)

;; Public function to get system protocol implementation
(define-read-only (get-system-protocol (system principal) (protocol-id (string-ascii 32)))
  (map-get? system-protocols { system: system, protocol-id: protocol-id })
)

;; Public function to update protocol status (admin only)
(define-public (update-protocol-status
    (protocol-id (string-ascii 32))
    (new-status (string-ascii 16)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-some (map-get? supported-protocols { protocol-id: protocol-id })) (err u404))
    (ok (map-set supported-protocols
      { protocol-id: protocol-id }
      (merge (unwrap-panic (map-get? supported-protocols { protocol-id: protocol-id }))
             { status: new-status })
    ))
  )
)

;; Public function to transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (var-set admin new-admin))
  )
)
