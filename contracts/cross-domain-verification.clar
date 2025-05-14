;; Cross-Domain Verification Contract
;; Enables identity portability across different domains

(define-data-var admin principal tx-sender)

;; Map of verification requests
(define-map verification-requests
  { request-id: (buff 32) }
  {
    requester: principal,
    subject: principal,
    claims: (list 10 (string-ascii 64)),
    status: (string-ascii 16),
    created-at: uint,
    completed-at: (optional uint)
  }
)

;; Map of verification results
(define-map verification-results
  { request-id: (buff 32), claim: (string-ascii 64) }
  {
    verifier: principal,
    result: bool,
    attestation: (buff 256),
    verified-at: uint
  }
)

;; Public function to create a verification request
(define-public (create-verification-request
    (request-id (buff 32))
    (subject principal)
    (claims (list 10 (string-ascii 64))))
  (begin
    (asserts! (not (is-some (map-get? verification-requests { request-id: request-id }))) (err u100))
    (ok (map-set verification-requests
      { request-id: request-id }
      {
        requester: tx-sender,
        subject: subject,
        claims: claims,
        status: "pending",
        created-at: block-height,
        completed-at: none
      }
    ))
  )
)

;; Public function to submit verification result
(define-public (submit-verification-result
    (request-id (buff 32))
    (claim (string-ascii 64))
    (result bool)
    (attestation (buff 256)))
  (let ((request (unwrap! (map-get? verification-requests { request-id: request-id }) (err u404))))
    (begin
      (asserts! (is-eq (get status request) "pending") (err u403))
      (asserts! (>= (len (get claims request)) u1) (err u400))
      (asserts! (is-some (index-of (get claims request) claim)) (err u400))
      (ok (map-set verification-results
        { request-id: request-id, claim: claim }
        {
          verifier: tx-sender,
          result: result,
          attestation: attestation,
          verified-at: block-height
        }
      ))
    )
  )
)

;; Public function to complete verification request
(define-public (complete-verification-request (request-id (buff 32)))
  (let ((request (unwrap! (map-get? verification-requests { request-id: request-id }) (err u404))))
    (begin
      (asserts! (is-eq (get status request) "pending") (err u403))
      (asserts! (or (is-eq tx-sender (var-get admin)) (is-eq tx-sender (get requester request))) (err u403))
      (ok (map-set verification-requests
        { request-id: request-id }
        (merge request {
          status: "completed",
          completed-at: (some block-height)
        })
      ))
    )
  )
)

;; Public function to get verification request details
(define-read-only (get-verification-request (request-id (buff 32)))
  (map-get? verification-requests { request-id: request-id })
)

;; Public function to get verification result for a claim
(define-read-only (get-verification-result (request-id (buff 32)) (claim (string-ascii 64)))
  (map-get? verification-results { request-id: request-id, claim: claim })
)

;; Public function to transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (var-set admin new-admin))
  )
)
