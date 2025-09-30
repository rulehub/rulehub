## Policy Title Synchronization Plan

Purpose: Replace placeholder string `<Policy Title>` in metadata and addon policy annotations with human‑readable, canonical titles. This plan lists every file still containing the placeholder, the policy id, and a proposed real title. No files are modified yet; this is a preparation step for a subsequent batch change + review.

Conventions / Rules Applied:
1. Preserve regulatory/acronym capitalization (HIPAA, ISO, IEC, GDPR, MDR, IVDR, MHRA, DTAC, ONC, FHIR, SBOM, PMS, PSUR, EUDAMED).
2. Expand obvious context where helpful (e.g., "21 CFR Part 11").
3. Use spaces and slashes for paired abbreviations ("PMS / PSUR").
4. Keep wording concise; avoid trailing words like "Requirement" unless clarity requires.
5. Country codes (AU, CA, EU, UK, SG) retained as uppercase prefixes.
6. Where underlying abbreviation meaning could vary (e.g., MYR), chose common interpretation "My Health Records" (note below) — flag for reviewer confirmation.

Legend Notes column markers:
- (VERIFY) = Please confirm phrasing / expansion correctness.
- (ACRONYM) = Intentional acronym kept as-is.

| Policy ID | File Path | Proposed Title | Notes |
|-----------|-----------|----------------|-------|
| medtech.uk_mhra_post_market_surveillance | policies/medtech/uk_mhra_post_market_surveillance/metadata.yaml | UK MHRA Post-Market Surveillance | ACRONYM |
| medtech.sg_hcsa_pdpa_health_data | policies/medtech/sg_hcsa_pdpa_health_data/metadata.yaml | SG HCSA PDPA Health Data | ACRONYM |
| medtech.uk_dtac_compliance | policies/medtech/uk_dtac_compliance/metadata.yaml | UK DTAC Compliance | ACRONYM |
| medtech.iso_27001_isms_scope_and_controls | policies/medtech/iso_27001_isms_scope_and_controls/metadata.yaml | ISO 27001 ISMS Scope and Controls | ACRONYM |
| medtech.iso_13485_document_control | policies/medtech/iso_13485_document_control/metadata.yaml | ISO 13485 Document Control | ACRONYM |
| medtech.log_retention_for_clinical_events | policies/medtech/log_retention_for_clinical_events/metadata.yaml | Log Retention for Clinical Events |  |
| medtech.iso_14971_risk_management_file | policies/medtech/iso_14971_risk_management_file/metadata.yaml | ISO 14971 Risk Management File | ACRONYM |
| medtech.gdpr_art9_special_category_safeguards | policies/medtech/gdpr_art9_special_category_safeguards/metadata.yaml | GDPR Article 9 Special Category Safeguards | ACRONYM |
| medtech.onc_cures_api_fhir_r4 | policies/medtech/onc_cures_api_fhir_r4/metadata.yaml | ONC Cures API FHIR R4 | ACRONYM |
| medtech.onc_information_blocking_prohibited | policies/medtech/onc_information_blocking_prohibited/metadata.yaml | ONC Information Blocking Prohibited | ACRONYM |
| medtech.hipaa_security_tech_encryption | policies/medtech/hipaa_security_tech_encryption/metadata.yaml | HIPAA Security Technical Encryption | ACRONYM |
| medtech.hipaa_security_admin_safeguards | policies/medtech/hipaa_security_admin_safeguards/metadata.yaml | HIPAA Security Administrative Safeguards | ACRONYM |
| medtech.hitech_breach_notification_60d | policies/medtech/hitech_breach_notification_60d/metadata.yaml | HITECH Breach Notification (60d) | ACRONYM |
| medtech.iec_62304_scm_prp_processes | policies/medtech/iec_62304_scm_prp_processes/metadata.yaml | IEC 62304 SCM PRP Processes | ACRONYM (VERIFY PRP) |
| medtech.iec_62366_usability_summative_eval | policies/medtech/iec_62366_usability_summative_eval/metadata.yaml | IEC 62366 Usability Summative Evaluation | ACRONYM |
| medtech.iec_62304_software_safety_class | policies/medtech/iec_62304_software_safety_class/metadata.yaml | IEC 62304 Software Safety Class | ACRONYM |
| medtech.hipaa_access_audit_logging | policies/medtech/hipaa_access_audit_logging/metadata.yaml | HIPAA Access Audit Logging | ACRONYM |
| medtech.hipaa_baa_with_vendors | policies/medtech/hipaa_baa_with_vendors/metadata.yaml | HIPAA BAA with Vendors | ACRONYM |
| medtech.hipaa_mfa_privileged_access | policies/medtech/hipaa_mfa_privileged_access/metadata.yaml | HIPAA MFA Privileged Access | ACRONYM |
| medtech.fhir_smart_app_authz | policies/medtech/fhir_smart_app_authz/metadata.yaml | FHIR SMART App Authorization | ACRONYM |
| medtech.backup_and_recovery_rto_rpo | policies/medtech/backup_and_recovery_rto_rpo/metadata.yaml | Backup and Recovery RTO/RPO |  |
| medtech.device_data_integrity_hashing | policies/medtech/device_data_integrity_hashing/metadata.yaml | Device Data Integrity Hashing |  |
| medtech.dicom_network_security_basic | policies/medtech/dicom_network_security_basic/metadata.yaml | DICOM Network Security (Basic) | ACRONYM |
| medtech.eu_ivdr_clinical_performance | policies/medtech/eu_ivdr_clinical_performance/metadata.yaml | EU IVDR Clinical Performance | ACRONYM |
| medtech.eu_mdr_ce_marking_and_udi | policies/medtech/eu_mdr_ce_marking_and_udi/metadata.yaml | EU MDR CE Marking and UDI | ACRONYM |
| medtech.eu_mdr_clinical_evaluation | policies/medtech/eu_mdr_clinical_evaluation/metadata.yaml | EU MDR Clinical Evaluation | ACRONYM |
| medtech.eu_mdr_eudamed_registration | policies/medtech/eu_mdr_eudamed_registration/metadata.yaml | EU MDR EUDAMED Registration | ACRONYM |
| medtech.eu_mdr_pms_psur | policies/medtech/eu_mdr_pms_psur/metadata.yaml | EU MDR PMS / PSUR | ACRONYM |
| medtech.eu_vigilance_incident_reporting | policies/medtech/eu_vigilance_incident_reporting/metadata.yaml | EU Vigilance Incident Reporting |  |
| medtech.fda_cybersecurity_524b_sbom | policies/medtech/fda_cybersecurity_524b_sbom/metadata.yaml | FDA Cybersecurity 524B SBOM | ACRONYM |
| medtech.fda_mdr_event_reporting | policies/medtech/fda_mdr_event_reporting/metadata.yaml | FDA MDR Event Reporting | ACRONYM |
| medtech.fda_part11_audit_trail | policies/medtech/fda_part11_audit_trail/metadata.yaml | FDA 21 CFR Part 11 Audit Trail | ACRONYM |
| medtech.fda_part11_esign_linkage | policies/medtech/fda_part11_esign_linkage/metadata.yaml | FDA 21 CFR Part 11 e-Sign Linkage | ACRONYM |
| medtech.fda_part11_system_validation | policies/medtech/fda_part11_system_validation/metadata.yaml | FDA 21 CFR Part 11 System Validation | ACRONYM |
| medtech.health_data_cross_border_controls | policies/medtech/health_data_cross_border_controls/metadata.yaml | Health Data Cross-Border Controls |  |
| medtech.au_myr_health_privacy | policies/medtech/au_myr_health_privacy/metadata.yaml | AU My Health Records Privacy | VERIFY (MyHR?) |
| medtech.ca_phipa_health_data | policies/medtech/ca_phipa_health_data/metadata.yaml | CA PHIPA Health Data | ACRONYM |

Addon Kyverno Policies (annotation rulehub.title): same title mapping applies — update `addons/kyverno/policies/*-policy.yaml` entries where `rulehub.title: <Policy Title>` using the Proposed Title derived above (replace `medtech-<rest>` hyphenated id segments with the matching metadata id's Proposed Title).

Next Steps (Implementation Outline):
1. Approve / adjust any titles flagged (VERIFY).
2. Batch update metadata.yaml `name:` fields and Kyverno annotation `rulehub.title`.
3. Run `make validate-metadata-schema` and any index/build steps (`make catalog`) to ensure no regressions.
4. Commit with message: "feat: sync policy titles (replace <Policy Title> placeholders)".

Review Checklist Before Applying Changes:
- [ ] All placeholders enumerated (search `<Policy Title>` now returns 0 after change except in templates).
- [ ] Acronyms retain intended capitalization.
- [ ] No unintended semantic drift (e.g., regulatory scope changes).
- [ ] Template placeholders in `templates/policy/` remain untouched.

Prepared: automated assist plan (no modifications yet).
