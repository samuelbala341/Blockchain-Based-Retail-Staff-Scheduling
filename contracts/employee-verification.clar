;; Employee Verification Contract
;; Confirms qualified staff members

(define-data-var last-employee-id uint u0)

;; Employee data structure
(define-map employees
  { employee-id: uint }
  {
    name: (string-ascii 100),
    address: principal,
    store-id: uint,
    role: (string-ascii 50),
    qualifications: (list 10 (string-ascii 50)),
    verified: bool,
    active: bool
  }
)

;; Employee store assignments
(define-map employee-stores
  { employee-id: uint, store-id: uint }
  { authorized: bool }
)

;; Register a new employee
(define-public (register-employee
    (name (string-ascii 100))
    (store-id uint)
    (role (string-ascii 50))
    (qualifications (list 10 (string-ascii 50))))
  (let
    (
      (new-id (+ (var-get last-employee-id) u1))
    )
    (asserts! (is-eq tx-sender contract-caller) (err u403))
    (var-set last-employee-id new-id)
    (map-set employees
      { employee-id: new-id }
      {
        name: name,
        address: tx-sender,
        store-id: store-id,
        role: role,
        qualifications: qualifications,
        verified: false,
        active: true
      }
    )
    (map-set employee-stores
      { employee-id: new-id, store-id: store-id }
      { authorized: true }
    )
    (ok new-id)
  )
)

;; Verify an employee (store owner only)
(define-public (verify-employee (employee-id uint))
  (let
    (
      (employee (unwrap! (map-get? employees { employee-id: employee-id }) (err u404)))
      (store-id (get store-id employee))
    )
    (asserts! (is-eq tx-sender contract-caller) (err u403))
    (map-set employees
      { employee-id: employee-id }
      (merge employee { verified: true })
    )
    (ok true)
  )
)

;; Add employee to a store
(define-public (add-employee-to-store (employee-id uint) (store-id uint))
  (let
    (
      (employee (unwrap! (map-get? employees { employee-id: employee-id }) (err u404)))
    )
    (asserts! (is-eq tx-sender contract-caller) (err u403))
    (map-set employee-stores
      { employee-id: employee-id, store-id: store-id }
      { authorized: true }
    )
    (ok true)
  )
)

;; Remove employee from a store
(define-public (remove-employee-from-store (employee-id uint) (store-id uint))
  (let
    (
      (employee (unwrap! (map-get? employees { employee-id: employee-id }) (err u404)))
    )
    (asserts! (is-eq tx-sender contract-caller) (err u403))
    (map-set employee-stores
      { employee-id: employee-id, store-id: store-id }
      { authorized: false }
    )
    (ok true)
  )
)

;; Deactivate an employee
(define-public (deactivate-employee (employee-id uint))
  (let
    (
      (employee (unwrap! (map-get? employees { employee-id: employee-id }) (err u404)))
    )
    (asserts! (is-eq (get address employee) tx-sender) (err u403))
    (map-set employees
      { employee-id: employee-id }
      (merge employee { active: false })
    )
    (ok true)
  )
)

;; Get employee details
(define-read-only (get-employee (employee-id uint))
  (map-get? employees { employee-id: employee-id })
)

;; Check if employee is verified
(define-read-only (is-employee-verified (employee-id uint))
  (match (map-get? employees { employee-id: employee-id })
    employee (get verified employee)
    false
  )
)

;; Check if employee is authorized for a store
(define-read-only (is-employee-authorized (employee-id uint) (store-id uint))
  (match (map-get? employee-stores { employee-id: employee-id, store-id: store-id })
    auth-data (get authorized auth-data)
    false
  )
)
