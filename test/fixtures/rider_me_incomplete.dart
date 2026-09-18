/// A real `GET /rider/me` response (2026-09-18) for a rider who registered
/// and uploaded every document but hasn't filled in the rest of the profile.
const riderMeIncompleteJson = r'''
{
  "success": true,
  "message": "Rider profile retrieved successfully",
  "data": {
    "id": 1,
    "rider_code": "01M2R55RKZV5F8M8KYS2TDC420",
    "first_name": "Ampaw",
    "last_name": "Hu",
    "name": "Ampaw Hu",
    "email": "ampawsafo22@gmail.com",
    "phone": "233548790987",
    "date_of_birth": null,
    "residential_address": null,
    "city": "Accra",
    "profile_photo_url": "https://api.bagyesrushdelivery.com/storage/riders/01M2R55RKZV5F8M8KYS2TDC420/photo/75dee7ed-5b17-44ec-aa1d-3e0b67a90343.jpg",
    "identity": {"type": "ghana_card", "type_label": "Ghana Card", "number": null},
    "vehicle": {
      "type_id": 1, "type": "motorbike", "type_label": "Motorbike",
      "requires_plate": true, "plate_number": "GR42",
      "make_id": null, "make": null, "model_id": null, "model": null,
      "colour": null, "year": 2025,
      "ownership": "owned", "ownership_label": "Owned by the rider"
    },
    "licence": {
      "number": null, "class": null, "expires_at": null,
      "permit_number": null, "permit_expires_at": null
    },
    "insurance": {
      "provider": null, "policy_number": null, "expires_at": null,
      "roadworthy_expires_at": null
    },
    "credentials": {"expired": [], "expiring_soon": []},
    "availability": {
      "operating_areas": [], "operating_days": [],
      "shift_start_time": null, "shift_end_time": null
    },
    "consent": {
      "terms_accepted_at": "2026-09-17T17:03:38.000000Z",
      "terms_version": "2026.09-10pct",
      "data_consent_at": "2026-09-17T17:03:38.000000Z",
      "is_complete": true, "agreement": null,
      "current_version": "placeholder-v1", "current_agreement_id": 1,
      "needs_reacceptance": true
    },
    "emergency_contact": {"name": null, "phone": null, "relationship": null},
    "status": "pending_review",
    "status_label": "Pending review",
    "rejection_reason": null,
    "is_active": true,
    "is_profile_complete": false,
    "missing_profile_fields": [
      "date_of_birth", "id_number", "residential_address",
      "emergency_contact_name", "emergency_contact_phone",
      "emergency_contact_relationship", "vehicle_make_id", "vehicle_model_id",
      "licence_number", "licence_class", "licence_expires_at",
      "insurance_provider", "insurance_policy_number", "insurance_expires_at",
      "payout_details"
    ],
    "approved_at": null,
    "is_online": false,
    "can_go_online": false,
    "max_delivery_radius_km": null,
    "documents": {
      "ghana_card_front": {"uploaded": true, "required": true},
      "ghana_card_back": {"uploaded": true, "required": true},
      "passport_bio_page": {"uploaded": false, "required": false},
      "drivers_licence_front": {"uploaded": true, "required": true},
      "drivers_licence_back": {"uploaded": true, "required": true},
      "rider_permit": {"uploaded": false, "required": false},
      "vehicle_registration": {"uploaded": true, "required": true},
      "vehicle_authorisation": {"uploaded": false, "required": false},
      "insurance_certificate": {"uploaded": true, "required": true},
      "roadworthy_certificate": {"uploaded": true, "required": true}
    },
    "documents_status": "pending",
    "documents_reviewed_at": null,
    "payout": {
      "bank": null, "payout_provider_id": null, "account_name": null,
      "account_number_last4": null, "momo_provider": null,
      "momo_provider_id": null, "mobile_money_number_last4": null,
      "is_configured": false
    },
    "created_at": "2026-09-17T17:03:37.000000Z",
    "updated_at": "2026-09-18T11:09:17.000000Z"
  }
}
''';
