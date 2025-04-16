;; Compliance Tracking Contract
;; Monitors adherence to labor regulations

;; Work record structure
(define-map work-records
  { employee-id: uint, date: uint }
  {
    total-hours: uint,
    breaks: (list 5 { start-time: uint, end-time: uint }),
    overtime: uint,
    compliance-issues: (list 5 (string-ascii 100))
  }
)

;; Labor regulations
(define-map labor-regulations
  { region: (string-ascii 50) }
  {
    max-daily-hours: uint,
    max-weekly-hours: uint,
    required-break-minutes: uint,
    min-break-interval-hours: uint
  }
)

;; Record work hours
(define-public (record-work-hours (employee-id uint) (date uint) (hours uint))
  (let
    (
      (existing-record (map-get? work-records { employee-id: employee-id, date: date }))
    )
    (asserts! (is-eq tx-sender contract-caller) (err u403))
    (if (is-some existing-record)
      (map-set work-records
        { employee-id: employee-id, date: date }
        (merge (unwrap-panic existing-record) { total-hours: hours })
      )
      (map-set work-records
        { employee-id: employee-id, date: date }
        {
          total-hours: hours,
          breaks: (list),
          overtime: u0,
          compliance-issues: (list)
        }
      )
    )
    (ok true)
  )
)

;; Record a break
(define-public (record-break (employee-id uint) (date uint) (start-time uint) (end-time uint))
  (let
    (
      (existing-record (unwrap! (map-get? work-records { employee-id: employee-id, date: date }) (err u404)))
      (current-breaks (get breaks existing-record))
      (new-break { start-time: start-time, end-time: end-time })
    )
    (asserts! (is-eq tx-sender contract-caller) (err u403))
    (asserts! (< start-time end-time) (err u400))
    (map-set work-records
      { employee-id: employee-id, date: date }
      (merge existing-record {
        breaks: (append current-breaks new-break)
      })
    )
    (ok true)
  )
)

;; Record overtime
(define-public (record-overtime (employee-id uint) (date uint) (hours uint))
  (let
    (
      (existing-record (unwrap! (map-get? work-records { employee-id: employee-id, date: date }) (err u404)))
    )
    (asserts! (is-eq tx-sender contract-caller) (err u403))
    (map-set work-records
      { employee-id: employee-id, date: date }
      (merge existing-record { overtime: hours })
    )
    (ok true)
  )
)

;; Flag compliance issue
(define-public (flag-compliance-issue (employee-id uint) (date uint) (issue (string-ascii 100)))
  (let
    (
      (existing-record (unwrap! (map-get? work-records { employee-id: employee-id, date: date }) (err u404)))
      (current-issues (get compliance-issues existing-record))
    )
    (asserts! (is-eq tx-sender contract-caller) (err u403))
    (map-set work-records
      { employee-id: employee-id, date: date }
      (merge existing-record {
        compliance-issues: (append current-issues issue)
      })
    )
    (ok true)
  )
)

;; Set labor regulations for a region
(define-public (set-labor-regulations
    (region (string-ascii 50))
    (max-daily-hours uint)
    (max-weekly-hours uint)
    (required-break-minutes uint)
    (min-break-interval-hours uint))
  (asserts! (is-eq tx-sender contract-caller) (err u403))
  (map-set labor-regulations
    { region: region }
    {
      max-daily-hours: max-daily-hours,
      max-weekly-hours: max-weekly-hours,
      required-break-minutes: required-break-minutes,
      min-break-interval-hours: min-break-interval-hours
    }
  )
  (ok true)
)

;; Get work record
(define-read-only (get-work-record (employee-id uint) (date uint))
  (map-get? work-records { employee-id: employee-id, date: date })
)

;; Get labor regulations for a region
(define-read-only (get-labor-regulations (region (string-ascii 50)))
  (map-get? labor-regulations { region: region })
)

;; Check if employee has compliance issues
(define-read-only (has-compliance-issues (employee-id uint) (date uint))
  (match (map-get? work-records { employee-id: employee-id, date: date })
    record (> (len (get compliance-issues record)) u0)
    false
  )
)
