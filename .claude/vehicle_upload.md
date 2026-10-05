# RIDER VEHICLE KYC / VERIFICATION

## Motorcycle-First, Multi-Vehicle Production Implementation

### ROLE

Act as a **Senior/Principal Flutter Engineer, Mobile Security Engineer, API Integration Engineer, Product Architect, and UX Engineer**.

You are implementing a **production-grade Vehicle KYC and Vehicle Verification system** for the **Rider side of the delivery application**.

The primary vehicle used by riders is expected to be **MOTORCYCLES**, but the architecture must also support other vehicle types such as:

* Motorcycle
* Car
* Van
* Pickup
* Truck
* Bicycle
* Other supported delivery vehicles

**IMPORTANT: Do NOT build this as a car verification feature.**

Build a reusable **Vehicle Verification Framework** where the capture requirements, instructions, validation rules, and displayed information can change according to the selected vehicle type.

Motorcycles must receive first-class treatment because they are the primary rider vehicle.

---

# 1. CORE PRODUCT OBJECTIVE

The purpose of this feature is to allow a rider to:

1. Register/select their delivery vehicle.
2. Provide required vehicle information.
3. Start a secure vehicle verification session.
4. Capture **LIVE photos using the device camera**.
5. Prevent normal gallery uploads for KYC evidence.
6. Capture the appropriate views of the vehicle based on its type.
7. Capture the registration plate clearly.
8. Capture other required identifiers/documents where applicable.
9. Submit the evidence securely to the backend.
10. Track verification status.
11. View the verified vehicle information from the Profile page.
12. Correct and resubmit rejected verification.
13. Trigger re-verification whenever the rider changes their vehicle.

The final system must be:

* Secure
* Robust
* Maintainable
* Responsive
* Efficient
* Testable
* API-driven
* Backend-authoritative
* Motorcycle-first
* Extensible to other vehicle types

---

# 2. FIRST ACTION — INSPECT THE EXISTING PROJECT

DO NOT immediately start coding.

First inspect the entire rider application and understand:

### Architecture

* Flutter architecture
* Provider / ChangeNotifier / ViewModel implementation
* Repository pattern
* Dependency injection
* Models
* State management
* Routing
* API layer
* Dio configuration
* Authentication interceptor
* Secure storage
* Error handling
* Existing reusable widgets

### Existing rider functionality

Find:

* Rider Profile
* Rider account model
* Rider registration
* Vehicle registration
* Vehicle models
* Vehicle APIs
* Delivery eligibility
* Rider onboarding
* Existing KYC functionality
* Existing image upload functionality
* Existing camera implementation
* Existing permissions handling

### IMPORTANT

This project already uses the existing:

**Provider + ChangeNotifier + ViewModel + Repository architecture.**

Continue using that architecture.

DO NOT introduce:

* Riverpod
* Bloc
* Cubit
* GetX
* Redux
* another state-management architecture

unless the project already contains it and it is genuinely required.

Do not rewrite the existing architecture.

---

# 3. DO NOT ASSUME API CONTRACTS

Before implementing API integrations, search the project for existing:

* vehicle endpoints
* rider endpoints
* profile endpoints
* KYC endpoints
* image upload endpoints
* multipart requests
* vehicle models
* registration models
* API response wrappers

Use existing APIs if available.

If an API does not exist:

DO NOT invent an endpoint and pretend it exists.

Instead:

1. Define the proposed API contract.
2. Isolate it behind the Repository.
3. Clearly mark backend dependencies.
4. Implement the Flutter side so integration can be completed without architectural changes.

---

# 4. VEHICLE KYC MUST BE VEHICLE-TYPE AWARE

Create a vehicle-type configuration rather than hardcoding motorcycle logic throughout the application.

Example concept:

```text
VehicleType
 ├── motorcycle
 ├── car
 ├── van
 ├── pickup
 ├── truck
 ├── bicycle
 └── other
```

Then define verification requirements based on the vehicle type.

Example:

```text
Motorcycle
 ├── front
 ├── rear
 ├── left_side
 ├── right_side
 └── registration_plate

Car
 ├── front
 ├── rear
 ├── left_side
 ├── right_side
 └── registration_plate

Bicycle
 ├── front
 ├── side
 └── identification_mark / serial_number where applicable
```

Do not duplicate the entire KYC implementation for each vehicle type.

Instead create reusable:

```text
VehicleVerificationConfiguration
VehicleCaptureRequirement
VehicleCaptureType
VehicleVerificationSession
```

---

# 5. MOTORCYCLE IS THE PRIMARY USE CASE

The UX and capture instructions must prioritize motorcycles.

Do not show instructions such as:

> "Capture the full front of your car."

Instead dynamically generate:

> "Capture the full front of your motorcycle."

Likewise:

> "Capture the full rear of your motorcycle."

The application must understand that motorcycles have a very different visual structure from cars.

For motorcycles, the camera guidance should prioritize:

* entire motorcycle
* front wheel
* rear wheel
* body/frame
* handlebars
* fuel tank/body
* rear section
* registration plate
* distinctive identifying features

Do not expect a motorcycle to fit into a car-shaped rectangular detection frame.

---

# 6. MOTORCYCLE CAPTURE FLOW

The default motorcycle verification flow should be approximately:

```text
Vehicle Information
        ↓
Verification Requirements
        ↓
Create Verification Session
        ↓
Camera Permission
        ↓
Front View
        ↓
Rear View
        ↓
Left Side
        ↓
Right Side
        ↓
Registration Plate
        ↓
Optional Vehicle Identifier
        ↓
Review Evidence
        ↓
Upload
        ↓
Submit
        ↓
Under Review
        ↓
Verified / Rejected
```

The backend should determine whether every step is mandatory.

Do not hardcode every requirement directly inside the UI.

---

# 7. MOTORCYCLE FRONT CAPTURE

Instruction:

> "Stand in front of your motorcycle and capture the complete motorcycle."

The system should attempt to ensure:

* motorcycle is sufficiently visible
* front wheel is visible
* handlebars are visible
* major body/frame is visible
* image is reasonably sharp
* lighting is sufficient
* motorcycle is not significantly obstructed

Do not require a rectangular car-like silhouette.

The capture guide should accommodate the tall/narrow geometry of a motorcycle.

---

# 8. MOTORCYCLE REAR CAPTURE

Instruction:

> "Stand behind your motorcycle and capture the complete rear view."

Try to capture:

* rear wheel
* rear body/frame
* seat
* rear registration plate
* major identifying features

Where applicable.

---

# 9. MOTORCYCLE LEFT-SIDE CAPTURE

Instruction:

> "Capture the full left side of your motorcycle."

The rider should move far enough away to capture the entire motorcycle.

The UI should detect/guide the rider if the motorcycle is too close or significantly outside the frame.

---

# 10. MOTORCYCLE RIGHT-SIDE CAPTURE

Instruction:

> "Capture the full right side of your motorcycle."

Again:

* complete motorcycle
* good lighting
* sufficient image quality
* minimal obstruction

---

# 11. REGISTRATION PLATE CAPTURE

This is a critical capture.

Instruction:

> "Move closer and capture a clear photo of your motorcycle's registration plate."

The registration plate should be:

* clearly visible
* readable
* reasonably centered
* sufficiently sharp
* adequately illuminated

If OCR is available, use it as an additional verification signal.

Example:

```text
Entered:
GR 1234-24

OCR:
GR123424

Normalized:
GR123424

Result:
Possible match
```

Do not automatically reject solely based on OCR.

---

# 12. MOTORCYCLE IDENTIFICATION

Where required by the backend, allow a separate capture for:

* VIN
* chassis number
* engine number
* frame number
* manufacturer identification label

For motorcycles, **chassis/frame identification may be more relevant than a car-style VIN workflow**, depending on the vehicle and backend requirements.

Do not assume every motorcycle has the same identification format.

The backend should define the required identifier.

---

# 13. OWNERSHIP / AUTHORIZATION

Vehicle verification must distinguish between:

```text
owned
rented
company_vehicle
family_vehicle
authorized_vehicle
other
```

If the rider does not own the motorcycle, the application must not incorrectly state that they do.

Depending on backend requirements, support:

```text
Ownership verification
+
Vehicle verification
```

as separate concepts.

For example:

```text
Vehicle:
Honda motorcycle

Ownership:
Rented

Vehicle Verification:
Verified

Ownership Authorization:
Pending
```

Do not merge these statuses into one boolean.

---

# 14. LIVE CAMERA ONLY

This is a strict requirement.

### NORMAL VEHICLE KYC EVIDENCE MUST NOT COME FROM THE GALLERY.

Do NOT implement:

```dart
ImagePicker.pickImage(
  source: ImageSource.gallery,
);
```

as the normal verification mechanism.

Use:

```text
Device Camera
↓
Live Preview
↓
Guided Capture
↓
Validation
↓
Capture
```

The rider must take a new photo during the verification session.

The UX should clearly explain:

> "For security, vehicle verification photos must be taken live. Photos from your gallery cannot be used."

---

# 15. WHY LIVE CAPTURE IS REQUIRED

The implementation should be designed to reduce:

* old vehicle photos
* screenshots
* downloaded images
* photos belonging to another rider
* edited vehicle images
* fraudulent submissions
* repeated use of previously submitted evidence

Do not claim that live camera capture alone completely prevents fraud.

It is one security layer.

---

# 16. VERIFICATION SESSION

Where backend support exists, create a verification session before opening the capture flow.

Conceptually:

```http
POST /riders/me/vehicle-verifications/sessions
```

Response:

```json
{
  "verificationId": "...",
  "sessionId": "...",
  "vehicleType": "motorcycle",
  "requiredCaptures": [
    "front",
    "rear",
    "left_side",
    "right_side",
    "registration_plate"
  ],
  "expiresAt": "..."
}
```

The app must use the backend-provided requirements where available.

Do not assume all vehicle types require the same evidence.

---

# 17. VEHICLE CAPTURE REQUIREMENT MODEL

Create a reusable concept such as:

```text
VehicleCaptureRequirement
```

Containing information such as:

```text
captureType
title
instruction
required
sequence
vehicleTypes
validationRules
```

Example:

```text
Motorcycle:
  front → required
  rear → required
  left_side → required
  right_side → required
  registration_plate → required

Bicycle:
  front → required
  side → required
  serial_number → optional/required depending on backend
```

This makes the system extensible.

---

# 18. CAMERA UX

Build a reusable:

```text
VehicleVerificationCamera
```

component.

It should support:

* live preview
* capture guide
* instructions
* step counter
* progress indicator
* flashlight
* camera switch if needed
* capture
* retake
* image review
* validation feedback
* permission state
* camera initialization state
* failure state

Example:

```text
Vehicle Verification

Motorcycle • Step 1 of 5

┌──────────────────────────┐
│                          │
│       LIVE CAMERA        │
│                          │
│      motorcycle          │
│       guide area         │
│                          │
└──────────────────────────┘

Capture the complete front
of your motorcycle.

        [ Capture ]
```

The guide must adapt according to vehicle type and capture type.

---

# 19. DO NOT USE A CAR-SHAPED MASK FOR EVERYTHING

This is specifically important.

A motorcycle is:

* narrower
* taller
* more vertically distributed
* less rectangular
* more exposed mechanically

Therefore the visual capture guide should adapt.

For example:

```text
Motorcycle front:
tall/vertical guide

Motorcycle side:
wide horizontal guide

Car front:
wide horizontal guide
```

Use responsive proportions rather than fixed pixel dimensions.

---

# 20. IMAGE QUALITY VALIDATION

Before accepting an image, perform reasonable checks:

### Quality

* blur
* darkness
* excessive brightness
* resolution
* compression artifacts

### Composition

* vehicle visibility
* vehicle position
* excessive cropping
* obstruction

### Capture type

Ensure the rider is attempting the requested view.

Do not make client-side validation so aggressive that legitimate motorcycle captures become impossible.

The goal is:

**Guide, not frustrate.**

---

# 21. OPTIONAL ON-DEVICE OBJECT DETECTION

Where practical, use on-device ML for capture assistance.

For example:

```text
Expected:
motorcycle

Detected:
motorcycle
```

or:

```text
Expected:
vehicle

Detected:
no suitable vehicle
```

This can help guide the rider.

However:

### NEVER treat client-side ML as the final KYC decision.

The backend remains authoritative.

Google ML Kit supports on-device object detection/tracking and real-time camera processing, making it suitable for capture guidance. [ML Kit Object Detection & Tracking](https://developers.google.com/ml-kit/vision/object-detection?utm_source=chatgpt.com)

---

# 22. DO NOT OVERENGINEER AI

Do not attempt to create an entire vehicle recognition/fraud detection platform inside Flutter.

Use client-side intelligence for:

* guidance
* object detection
* image quality
* OCR assistance

Use backend infrastructure for:

* final verification
* duplicate detection
* vehicle matching
* rider/vehicle association
* fraud scoring
* manual review
* approval/rejection

---

# 23. VEHICLE MODEL

Create or extend the existing vehicle model.

Conceptually:

```text
Vehicle
├── id
├── type
├── make
├── model
├── year
├── color
├── registrationNumber
├── chassisNumber
├── engineNumber
├── ownershipType
├── verificationStatus
├── verificationReason
├── verifiedAt
├── expiresAt
├── createdAt
└── updatedAt
```

Only implement fields supported by the actual backend.

Do not add meaningless fields just for completeness.

---

# 24. VEHICLE VERIFICATION STATUS

Use a strongly typed status.

Example:

```text
not_started
draft
capturing
uploading
submitted
under_review
verified
rejected
requires_resubmission
expired
suspended
```

Do not spread raw strings throughout the application.

---

# 25. IMPORTANT — VERIFICATION ≠ SUBMISSION

These are different states.

Example:

```text
Submitted
≠
Verified
```

The rider must not see:

```text
✓ Verified
```

simply because the upload succeeded.

Correct:

```text
Upload successful
→ Under review
→ Backend/Admin verification
→ Verified
```

---

# 26. PROFILE PAGE

The Profile page must display the rider's vehicle.

For motorcycle:

```text
Vehicle

[ Motorcycle Image ]

Honda
CB125 / Model
Black

Registration:
GR 1234-24

✓ Verified
```

If the actual backend model differs, use the available information.

---

# 27. PROFILE STATES

### Not verified

```text
Vehicle verification required

Verify your motorcycle to start
accepting deliveries.

[Verify Vehicle]
```

### Under review

```text
Vehicle verification

⏳ Under review

Your motorcycle verification is
being reviewed.
```

### Verified

```text
Vehicle

✓ Verified

Honda Motorcycle
GR 1234-24
```

### Rejected

```text
Vehicle verification

Action required

Registration plate was not clearly
visible.

[Resubmit]
```

### Expired

```text
Vehicle verification expired

Please complete verification again.

[Verify Again]
```

---

# 28. VERIFIED VEHICLE PHOTO

The Profile should display an appropriate verified vehicle image.

Prefer a backend-controlled image/reference rather than blindly trusting a local image.

If private storage is used:

* use secure URLs
* use short-lived signed URLs
* do not expose storage credentials
* do not log private image URLs

---

# 29. VEHICLE CHANGE

This is mandatory.

If a rider changes:

* vehicle type
* motorcycle
* registration number
* VIN/chassis
* major vehicle information

the vehicle must enter a new verification lifecycle.

Example:

```text
Current vehicle:
Honda Motorcycle
GR 1234-24
✓ Verified

Change vehicle?

Changing your vehicle requires
new verification before it can be
used for deliveries.

[Cancel]
[Continue]
```

Never automatically transfer verification from the previous vehicle.

---

# 30. MULTIPLE VEHICLES

Even if the current product only supports one active vehicle, design the domain so multiple vehicles can be supported later.

Conceptually:

```text
Rider
 └── Vehicles[]
       ├── Vehicle A
       ├── Vehicle B
       └── Vehicle C
```

One can be:

```text
active = true
```

Do not unnecessarily implement the entire multi-vehicle UI if the product does not require it now.

Just ensure the architecture does not prevent it later.

---

# 31. VEHICLE-TYPE-SPECIFIC REQUIREMENTS

Create a configuration layer.

Example:

```text
MotorcycleConfiguration
CarConfiguration
VanConfiguration
PickupConfiguration
TruckConfiguration
BicycleConfiguration
```

But avoid creating unnecessary classes if a data-driven configuration is cleaner.

Preferred conceptual design:

```text
VehicleTypeConfiguration
```

which provides:

```text
requiredCaptures
optionalCaptures
captureInstructions
validationRules
requiredIdentifiers
```

---

# 32. API LAYER

The repository should own API communication.

Conceptually:

```dart
abstract class VehicleRepository {
  Future<Either<Failure, VehicleVerificationSession>>
      createVerificationSession();

  Future<Either<Failure, VehicleVerificationCapture>>
      uploadCapture(...);

  Future<Either<Failure, VehicleVerification>>
      submitVerification(...);

  Future<Either<Failure, VehicleVerification>>
      getVerification();

  Future<Either<Failure, Vehicle>>
      getVehicle();
}
```

Adapt this to the existing repository architecture.

DO NOT place API calls inside widgets.

---

# 33. VIEWMODEL

The ViewModel should coordinate:

```text
Vehicle KYC
    ↓
verification session
    ↓
capture requirements
    ↓
camera state
    ↓
validation
    ↓
upload
    ↓
submission
    ↓
verification result
```

The UI should react to ViewModel state.

Do not put business logic into screens/widgets.

---

# 34. UPLOAD EFFICIENCY

Do not keep all high-resolution motorcycle images in RAM.

Use:

```text
Capture
↓
Validate
↓
Compress appropriately
↓
Persist temporarily
↓
Upload
↓
Release memory
↓
Continue
```

This is particularly important because riders may use lower-end Android devices.

Optimize for:

* memory
* bandwidth
* upload speed
* battery
* image quality

Do not destroy the quality required to read registration plates.

---

# 35. UPLOAD FAILURE

If an upload fails:

```text
Upload failed

Your captured photo is still available.

[Retry]
[Retake]
```

Do not force the rider to redo every successful capture.

---

# 36. SESSION EXPIRATION

If the verification session expires:

```text
Verification session expired

For your security, this verification
session is no longer valid.

[Start New Verification]
```

Do not reuse expired sessions.

---

# 37. AUTHENTICATION

Use the existing authentication infrastructure.

If API returns:

```text
401
```

use the project's existing token/session-expiration interceptor.

Do not implement another authentication system inside KYC.

---

# 38. SECURITY

Vehicle KYC data should be treated as sensitive.

Never:

* log image bytes
* log full private image URLs
* log access tokens
* store KYC images in SharedPreferences
* expose storage credentials
* trust client-side verification flags
* trust client-provided verification status
* rely on client-only security

The backend must be authoritative.

---

# 39. IMAGE SECURITY

Before upload:

* validate actual file format
* enforce file-size limits
* enforce reasonable resolution
* compress appropriately
* sanitize metadata where appropriate
* generate secure identifiers
* use HTTPS
* use private storage

Never trust:

```text filename
MIME type
client file extension
```

as the sole validation.

---

# 40. DUPLICATE / FRAUD DETECTION

Support backend signals for:

* duplicate image
* duplicate registration number
* vehicle already registered
* suspicious repeated submission
* reused evidence
* inconsistent vehicle information
* image manipulation
* vehicle mismatch

Use image hashes such as SHA-256 where useful for duplicate detection.

Do not treat hashing as a complete anti-fraud solution.

---

# 41. OWNERSHIP AUTHORIZATION

If a rider selects:

```text rented
company_vehicle
family_vehicle
authorized_vehicle
```

the backend may require additional evidence.

Design the flow so additional requirements can be added dynamically.

Example:

```text Motorcycle verification
        ↓
Vehicle evidence
        ↓
Ownership type = Rented
        ↓
Rental/authorization evidence required
```

Do not force these documents on riders who don't need them.

---

# 42. DOCUMENT CAPTURE

If the backend requires:

* rider's vehicle registration
* insurance
* roadworthiness
* authorization letter
* rental agreement

these should also use a secure capture mechanism where appropriate.

Keep:

```text vehicle evidence
```

and:

```text ownership/document evidence
```

as separate evidence types.

Do not mix everything into a generic image list.

---

# 43. VERIFICATION SESSION DATA

Each capture should conceptually contain:

```text
verificationId
sessionId
captureId
captureType
vehicleType
sequence
capturedAt
imageHash
uploadStatus
```

Do not trust client metadata as proof.

The backend should validate session state and capture sequence.

---

# 44. IDEMPOTENCY

Prevent duplicate submissions.

If backend supports it, use an idempotency key:

```text
Idempotency-Key
```

This prevents:

```text
Submit
Submit
Submit
```

from generating multiple verification requests.

The UI must also disable duplicate submission while the request is processing.

---

# 45. NETWORK FAILURE

Handle:

* no internet
* timeout
* server error
* 401
* 403
* 404
* 409
* 422
* 429
* 500
* 502
* 503

Convert backend errors into useful user-facing messages.

Do not show raw server exceptions to riders.

---

# 46. 409 / VEHICLE CONFLICT

If backend reports that a registration is already associated with another rider:

```text
Vehicle already registered

This vehicle appears to be associated
with another rider account.

Please contact support if you believe
this is incorrect.
```

Do not reveal another rider's personal information.

---

# 47. VERIFICATION REJECTION

Use structured reasons.

Examples:

```text
vehicle_not_visible
wrong_vehicle_type
registration_not_visible
registration_mismatch
image_blurry
image_too_dark
vehicle_obstructed
vehicle_already_registered
invalid_identifier
ownership_not_verified
manual_review_required
```

The backend should return the reason.

---

# 48. PROFILE REFRESH

After successful submission or verification:

```text
Submit
 ↓
Success
 ↓
Refresh Vehicle/Profile
 ↓
Update local state
 ↓
Profile reflects latest backend state
```

Do not require an app restart.

Avoid stale vehicle data.

---

# 49. DELIVERY ELIGIBILITY

If vehicle verification is mandatory before a rider can accept deliveries:

The mobile app may show:

```text
Vehicle verification required
```

and prevent the rider from proceeding.

However:

### THIS MUST NOT BE THE SECURITY BOUNDARY.

The backend must independently enforce:

```text
verified vehicle
+
eligible rider
=
allowed to accept delivery
```

Do not trust:

```text
isVerified = true
```

from the client.

---

# 50. CAMERA PERMISSIONS

Support:

```text
not_requested
granted
denied
permanently_denied
restricted
```

If denied:

```text
Camera access required

Vehicle verification requires a
live camera photo.

[Allow Camera]
```

If permanently denied:

```text
Camera permission is disabled.

Please enable camera access
from Settings.
```

Do not continuously prompt the rider.

---

# 51. CAMERA RESOURCE MANAGEMENT

Prevent memory leaks.

Properly:

* initialize camera
* dispose camera controller
* handle lifecycle changes
* handle background/foreground
* handle permission changes
* handle camera errors
* release image resources

This is particularly important because camera previews can consume significant memory.

---

# 52. APP LIFECYCLE

Handle:

```text
Camera opened
↓
User receives call
↓
App backgrounded
↓
App resumed
```

Do not assume the camera controller remains valid.

Reinitialize safely where required.

---

# 53. ACCESSIBILITY

Support:

* readable instructions
* semantic labels
* sufficient touch targets
* scalable text
* non-color-only status indicators
* clear error messages

Example:

```text
✓ Verified
```

must not communicate status only through green color.

---

# 54. UI DESIGN

Follow the existing rider application's design system.

Use:

* existing typography
* existing colors
* reusable buttons
* reusable cards
* existing spacing conventions
* responsive layouts

Avoid:

* unnecessary gradients
* excessive animations
* fancy visual effects
* giant cards
* fixed dimensions
* duplicated widgets

The experience should feel like a natural part of the existing rider app.

---

# 55. DO NOT HARD-CODE MOTORCYCLE EVERYWHERE

Bad:

```dart
if (vehicleType == 'motorcycle') {
   ...
}
```

repeated throughout multiple screens.

Instead centralize vehicle-specific requirements.

For example:

```text
VehicleVerificationConfiguration
```

Then:

```text
configuration.requiredCaptures
configuration.instructions
configuration.validationRules
```

This makes future vehicle types easier to add.

---

# 56. EXAMPLE CONFIGURATION

Conceptually:

```text
Motorcycle

required:
- front
- rear
- left_side
- right_side
- registration_plate

optional:
- chassis_number
- engine_number
- ownership_document
```

Car:

```text
required:
- front
- rear
- left_side
- right_side
- registration_plate
```

Bicycle:

```text
required:
- front
- side

optional:
- serial_number
```

Do not blindly implement these exact requirements if the backend/product requirements differ.

---

# 57. TESTING

Create tests for:

## Vehicle configuration

* motorcycle requirements
* car requirements
* unsupported vehicle type
* optional evidence
* required evidence

## ViewModel

* start session
* capture progression
* retry
* upload
* submission
* rejection
* resubmission
* expiration

## Repository

* successful response
* malformed response
* network failure
* timeout
* 401
* 409
* 422
* 500

## UI

* motorcycle flow
* car flow
* rejected state
* pending state
* verified state
* camera permission
* upload failure

---

# 58. CRITICAL EDGE CASES

Test all of these:

* Rider closes camera
* Rider denies camera permission
* Rider permanently denies camera permission
* Camera initialization fails
* App goes into background
* Rider loses internet
* Upload fails
* Token expires
* Session expires
* Rider presses capture repeatedly
* Rider presses submit repeatedly
* Image is too dark
* Image is too blurry
* Motorcycle is partially outside frame
* Wrong vehicle appears in frame
* Registration plate is unreadable
* OCR doesn't match
* Vehicle is already registered
* Verification rejected
* Vehicle changed after verification
* Verification expires
* App restarts during verification
* Device has insufficient storage

---

# 59. PERFORMANCE

Optimize for real rider devices.

Assume some riders may use:

* budget Android phones
* limited RAM
* slow mobile networks
* poor network coverage
* older cameras

Therefore:

* don't retain unnecessary full-resolution images
* don't perform expensive processing repeatedly
* compress intelligently
* release camera resources
* avoid unnecessary rebuilds
* avoid large synchronous operations on the UI thread
* upload sequentially unless the backend explicitly supports safe parallel uploads

---

# 60. DATA PRIVACY

Only collect information necessary for vehicle verification.

Do not unnecessarily collect:

* continuous location
* contacts
* unrelated device information
* unrelated personal data

If GPS/location is eventually used for verification, make it:

* explicitly required
* clearly explained
* appropriately permissioned
* sent only when necessary
* handled according to applicable privacy requirements

---

# 61. OBSERVABILITY

Track safe application events:

```text
vehicle_kyc_started
vehicle_kyc_session_created
vehicle_kyc_capture_started
vehicle_kyc_capture_completed
vehicle_kyc_upload_started
vehicle_kyc_upload_failed
vehicle_kyc_submitted
vehicle_kyc_rejected
vehicle_kyc_verified
vehicle_kyc_resubmitted
```

Never log:

* image bytes
* access tokens
* full VIN
* sensitive KYC documents
* private image URLs

---

# 62. FINAL ARCHITECTURE

The intended architecture should conceptually be:

```text
                 PROFILE
                    │
                    ▼
             VEHICLE DETAILS
                    │
                    ▼
           VEHICLE KYC VIEW
                    │
                    ▼
       VEHICLE CONFIGURATION
                    │
          ┌─────────┴─────────┐
          ▼                   ▼
     MOTORCYCLE              CAR
          │                   │
          ▼                   ▼
 Capture Requirements   Capture Requirements
          │                   │
          └─────────┬─────────┘
                    ▼
             CAMERA SERVICE
                    │
                    ▼
           CAPTURE VALIDATION
                    │
                    ▼
             IMAGE PROCESSOR
                    │
                    ▼
              REPOSITORY
                    │
                    ▼
                  API
                    │
                    ▼
            BACKEND VERIFICATION
                    │
          ┌─────────┴──────────┐
          ▼                    ▼
       VERIFIED             REJECTED
          │                    │
          ▼                    ▼
       PROFILE              RESUBMIT
```

---

# 63. FILE/CLASS ORGANIZATION

Follow the existing project structure.

Conceptually, the feature should have separation similar to:

```text
vehicle/
├── models/
│   ├── vehicle.dart
│   ├── vehicle_verification.dart
│   ├── vehicle_verification_session.dart
│   └── vehicle_capture.dart
│
├── repository/
│   └── vehicle_repository.dart
│
├── viewmodel/
│   └── vehicle_kyc_viewmodel.dart
│
├── services/
│   ├── vehicle_camera_service.dart
│   ├── vehicle_capture_validator.dart
│   └── vehicle_image_processor.dart
│
└── widgets/
    ├── vehicle_verification_camera.dart
    ├── vehicle_capture_step.dart
    ├── vehicle_verification_status.dart
    └── vehicle_profile_card.dart
```

Adapt this to the existing project structure instead of blindly creating this exact folder hierarchy.

---

# 64. ACCEPTANCE CRITERIA

The implementation is complete only when:

### General

* [ ] Vehicle KYC exists as a dedicated feature.
* [ ] Architecture follows the existing project.
* [ ] Provider/ChangeNotifier/ViewModel pattern is preserved.
* [ ] Repository handles API communication.
* [ ] No API calls are placed directly inside UI widgets.

### Motorcycle

* [ ] Motorcycle is the primary supported vehicle.
* [ ] Motorcycle-specific capture instructions exist.
* [ ] Motorcycle-specific framing/guidance exists.
* [ ] Front motorcycle capture exists.
* [ ] Rear motorcycle capture exists.
* [ ] Left-side capture exists.
* [ ] Right-side capture exists.
* [ ] Registration plate capture exists.
* [ ] Chassis/frame/engine identifier can be supported when required.

### Other vehicles

* [ ] Car can use the same framework.
* [ ] Additional vehicle types can be added without rewriting the entire feature.
* [ ] Vehicle-specific capture requirements are configuration-driven.

### Security

* [ ] Normal gallery upload is disabled for KYC.
* [ ] Live camera capture is used.
* [ ] Verification session is supported.
* [ ] Backend remains authoritative.
* [ ] Private images are securely handled.
* [ ] Sensitive information is not logged.
* [ ] Duplicate submissions are prevented.
* [ ] Vehicle changes require re-verification.
* [ ] 401 handling uses existing authentication infrastructure.

### UX

* [ ] Camera permission flow works.
* [ ] Capture instructions are clear.
* [ ] Capture progress is visible.
* [ ] Retake is supported.
* [ ] Upload progress is visible.
* [ ] Upload failure can be retried.
* [ ] Rejection reason is visible.
* [ ] Resubmission works.
* [ ] Profile displays vehicle verification status.

### Performance

* [ ] Camera resources are disposed.
* [ ] Images are not unnecessarily retained in memory.
* [ ] Image compression is implemented appropriately.
* [ ] Network failures are handled.
* [ ] App lifecycle is handled.

### Testing

* [ ] Unit tests added.
* [ ] ViewModel tests added.
* [ ] Repository tests added.
* [ ] Relevant widget tests added.
* [ ] `flutter analyze` passes.
* [ ] Relevant tests pass.

---

# 65. IMPLEMENTATION PROCESS

Follow this exact process.

## PHASE 1 — AUDIT

Inspect the project.

Report:

```text
Architecture
Existing vehicle implementation
Existing Profile implementation
Existing API infrastructure
Existing camera/image implementation
Existing authentication
Existing reusable components
Existing dependencies
Potential conflicts
```

DO NOT MODIFY CODE YET.

---

## PHASE 2 — DESIGN

Produce:

```text
Vehicle KYC architecture
Vehicle models
Verification states
Capture configuration
API contract
Camera strategy
Security strategy
Profile integration
Testing strategy
```

Identify anything requiring backend support.

---

## PHASE 3 — IMPLEMENTATION

Implement incrementally.

Do not modify unrelated functionality.

Reuse existing components where possible.

Do not introduce unnecessary dependencies.

---

## PHASE 4 — VALIDATION

Run:

```bash
flutter analyze
```

Then run relevant tests.

Fix:

* compile errors
* analyzer errors
* state issues
* lifecycle issues
* memory/resource issues
* API parsing issues
* navigation issues

---

## PHASE 5 — FINAL AUDIT

Perform a final review specifically for:

### Security

* gallery bypass
* client-side trust
* sensitive logging
* token exposure
* insecure URLs
* duplicate submissions

### Architecture

* API calls outside ViewModels
* business logic inside widgets
* duplicated logic
* unnecessary dependencies

### Performance

* camera memory leaks
* image memory usage
* unnecessary rebuilds
* upload efficiency

### UX

* motorcycle capture experience
* permission handling
* failure states
* retry
* resubmission
* Profile synchronization

---

# 66. FINAL REPORT

After implementation, provide:

## Implemented

List exactly what was implemented.

## Motorcycle Support

Explain the motorcycle-specific capture flow.

## Other Vehicle Support

Explain how the architecture supports cars and future vehicle types.

## API Integration

List actual endpoints used.

Clearly separate:

```text
Implemented backend endpoints
```

from:

```text
Backend endpoints still required
```

## Security

Explain:

* live camera capture
* verification session
* image handling
* backend authority
* duplicate prevention
* sensitive data handling

## Profile

Explain how verified vehicle information appears on Profile.

## Testing

List tests executed and results.

## Remaining Work

List only genuine remaining dependencies.

---

# FINAL NON-NEGOTIABLE RULES

1. **Motorcycles are the primary vehicle type.**
2. Do not design the feature as a car flow and simply rename the text.
3. Build a reusable vehicle-type-aware verification system.
4. Vehicle requirements must be configurable.
5. Normal gallery selection must NOT be allowed for KYC evidence.
6. Live camera capture is the default.
7. Client-side validation assists the rider but does NOT determine verification.
8. Backend verification is authoritative.
9. Never trust client-side `isVerified` flags.
10. Changing vehicles must trigger re-verification.
11. Do not invent backend endpoints.
12. Do not modify unrelated features.
13. Do not introduce a new architecture.
14. Do not introduce Riverpod/Bloc/GetX/etc.
15. Do not put API calls directly inside widgets.
16. Do not log sensitive KYC information.
17. Properly dispose camera/image resources.
18. Design for budget Android devices and unreliable mobile networks.
19. Do not make the rider repeat successful captures unnecessarily after a single upload failure.
20. Make the feature extensible for future vehicle types without duplicating the entire implementation.
21. Do not claim completion when backend dependencies are missing.
22. Prioritize correctness, security, maintainability, and rider usability over speed of implementation.

**Start by auditing the existing project. Do not write code until the audit and implementation plan are complete.**
