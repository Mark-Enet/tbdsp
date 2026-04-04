-- =============================================================================
-- TBDSP — The Big DataBase Standards Project
-- Domain   : Medical
-- Database : PostgreSQL 14+
-- File     : sample_data.sql
-- Version  : 1.0.0
-- Description:
--   Realistic sample data for the medical schema. Run schema.sql first.
--   All inserts are wrapped in a transaction so the load is atomic.
--   Includes 4 departments, 8 patients, 5 practitioners, 10 appointments,
--   8 encounters, 10 diagnoses, 12 medications, 10 prescriptions,
--   8 lab orders, and 16 lab results.
-- =============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- departments
-- ---------------------------------------------------------------------------
INSERT INTO departments (id, name, code, description) VALUES
    (1, 'General Practice',     'GP',   'Primary care and general outpatient consultations'),
    (2, 'Cardiology',           'CARD', 'Heart and cardiovascular system speciality'),
    (3, 'Emergency Medicine',   'EM',   'Acute and emergency presentations'),
    (4, 'Pathology & Labs',     'PATH', 'Laboratory services and diagnostic testing');

-- Advance the SERIAL sequence so new inserts don't collide with explicit IDs above.
SELECT setval('departments_id_seq', 4);

-- ---------------------------------------------------------------------------
-- patients
-- ---------------------------------------------------------------------------
INSERT INTO patients (
    id, email, password_hash,
    first_name, last_name, date_of_birth, gender,
    phone, address_line1, city, state, postal_code, country_code,
    emergency_contact_name, emergency_contact_phone
) VALUES
    (
        'a1000000-0000-0000-0000-000000000001',
        'alice.morgan@example.com',
        '$2b$12$examplehash_alice',
        'Alice', 'Morgan', '1985-03-14', 'female',
        '555-0101', '12 Maple Street', 'Springfield', 'IL', '62701', 'US',
        'Robert Morgan', '555-0102'
    ),
    (
        'a1000000-0000-0000-0000-000000000002',
        'brian.osei@example.com',
        '$2b$12$examplehash_brian',
        'Brian', 'Osei', '1978-07-22', 'male',
        '555-0201', '47 Oak Avenue', 'Springfield', 'IL', '62702', 'US',
        'Sandra Osei', '555-0202'
    ),
    (
        'a1000000-0000-0000-0000-000000000003',
        'claire.nguyen@example.com',
        '$2b$12$examplehash_claire',
        'Claire', 'Nguyen', '1992-11-05', 'female',
        '555-0301', '8 Pine Road', 'Chicago', 'IL', '60601', 'US',
        'Linh Nguyen', '555-0302'
    ),
    (
        'a1000000-0000-0000-0000-000000000004',
        'david.patel@example.com',
        '$2b$12$examplehash_david',
        'David', 'Patel', '1965-01-30', 'male',
        '555-0401', '33 Elm Court', 'Peoria', 'IL', '61602', 'US',
        'Priya Patel', '555-0402'
    ),
    (
        'a1000000-0000-0000-0000-000000000005',
        'eva.kowalczyk@example.com',
        '$2b$12$examplehash_eva',
        'Eva', 'Kowalczyk', '2001-06-18', 'female',
        '555-0501', '19 Birch Lane', 'Rockford', 'IL', '61101', 'US',
        'Jan Kowalczyk', '555-0502'
    ),
    (
        'a1000000-0000-0000-0000-000000000006',
        'frank.diaz@example.com',
        '$2b$12$examplehash_frank',
        'Frank', 'Diaz', '1950-09-12', 'male',
        '555-0601', '88 Cedar Blvd', 'Springfield', 'IL', '62703', 'US',
        'Maria Diaz', '555-0602'
    ),
    (
        'a1000000-0000-0000-0000-000000000007',
        'grace.obi@example.com',
        '$2b$12$examplehash_grace',
        'Grace', 'Obi', '1973-04-08', 'female',
        '555-0701', '5 Walnut Way', 'Chicago', 'IL', '60602', 'US',
        'Emeka Obi', '555-0702'
    ),
    (
        'a1000000-0000-0000-0000-000000000008',
        'henry.smith@example.com',
        '$2b$12$examplehash_henry',
        'Henry', 'Smith', '1988-12-25', 'male',
        '555-0801', '61 Ash Street', 'Peoria', 'IL', '61603', 'US',
        'Linda Smith', '555-0802'
    );

-- ---------------------------------------------------------------------------
-- practitioners
-- ---------------------------------------------------------------------------
INSERT INTO practitioners (
    id, department_id, email, password_hash,
    first_name, last_name, role, specialization, license_number, phone
) VALUES
    (
        'b1000000-0000-0000-0000-000000000001',
        1,
        'dr.james.harris@clinic.example.com',
        '$2b$12$examplehash_harris',
        'James', 'Harris', 'physician',
        'Family Medicine', 'IL-MD-100001', '555-1001'
    ),
    (
        'b1000000-0000-0000-0000-000000000002',
        2,
        'dr.sofia.larsson@clinic.example.com',
        '$2b$12$examplehash_larsson',
        'Sofia', 'Larsson', 'specialist',
        'Interventional Cardiology', 'IL-MD-100002', '555-1002'
    ),
    (
        'b1000000-0000-0000-0000-000000000003',
        3,
        'dr.michael.brown@clinic.example.com',
        '$2b$12$examplehash_brown',
        'Michael', 'Brown', 'physician',
        'Emergency Medicine', 'IL-MD-100003', '555-1003'
    ),
    (
        'b1000000-0000-0000-0000-000000000004',
        1,
        'np.rachel.kim@clinic.example.com',
        '$2b$12$examplehash_kim',
        'Rachel', 'Kim', 'nurse_practitioner',
        'Primary Care', 'IL-NP-200001', '555-1004'
    ),
    (
        'b1000000-0000-0000-0000-000000000005',
        4,
        'dr.lena.hoffmann@clinic.example.com',
        '$2b$12$examplehash_hoffmann',
        'Lena', 'Hoffmann', 'physician',
        'Clinical Pathology', 'IL-MD-100005', '555-1005'
    );

-- ---------------------------------------------------------------------------
-- appointments
-- ---------------------------------------------------------------------------
INSERT INTO appointments (
    id, patient_id, practitioner_id, department_id,
    scheduled_at, duration_minutes, status, reason
) VALUES
    (
        'c1000000-0000-0000-0000-000000000001',
        'a1000000-0000-0000-0000-000000000001',
        'b1000000-0000-0000-0000-000000000001',
        1, '2025-11-10 09:00:00+00', 30, 'completed',
        'Annual physical examination'
    ),
    (
        'c1000000-0000-0000-0000-000000000002',
        'a1000000-0000-0000-0000-000000000002',
        'b1000000-0000-0000-0000-000000000001',
        1, '2025-11-10 10:00:00+00', 30, 'completed',
        'Follow-up for hypertension management'
    ),
    (
        'c1000000-0000-0000-0000-000000000003',
        'a1000000-0000-0000-0000-000000000004',
        'b1000000-0000-0000-0000-000000000002',
        2, '2025-11-11 14:00:00+00', 45, 'completed',
        'Chest pain evaluation'
    ),
    (
        'c1000000-0000-0000-0000-000000000004',
        'a1000000-0000-0000-0000-000000000003',
        'b1000000-0000-0000-0000-000000000004',
        1, '2025-11-12 11:00:00+00', 20, 'completed',
        'Sore throat and fever'
    ),
    (
        'c1000000-0000-0000-0000-000000000005',
        'a1000000-0000-0000-0000-000000000005',
        'b1000000-0000-0000-0000-000000000001',
        1, '2025-11-13 09:30:00+00', 30, 'completed',
        'Routine contraception review'
    ),
    (
        'c1000000-0000-0000-0000-000000000006',
        'a1000000-0000-0000-0000-000000000006',
        'b1000000-0000-0000-0000-000000000002',
        2, '2025-11-14 15:00:00+00', 45, 'completed',
        'Post-operative cardiac follow-up'
    ),
    (
        'c1000000-0000-0000-0000-000000000007',
        'a1000000-0000-0000-0000-000000000007',
        'b1000000-0000-0000-0000-000000000001',
        1, '2025-12-01 10:00:00+00', 30, 'scheduled',
        'Diabetes management review'
    ),
    (
        'c1000000-0000-0000-0000-000000000008',
        'a1000000-0000-0000-0000-000000000008',
        'b1000000-0000-0000-0000-000000000004',
        1, '2025-12-02 11:30:00+00', 20, 'scheduled',
        'Persistent cough and fatigue'
    ),
    (
        'c1000000-0000-0000-0000-000000000009',
        'a1000000-0000-0000-0000-000000000002',
        'b1000000-0000-0000-0000-000000000002',
        2, '2025-12-05 13:00:00+00', 45, 'confirmed',
        'Cardiology referral — elevated troponin'
    ),
    (
        'c1000000-0000-0000-0000-000000000010',
        'a1000000-0000-0000-0000-000000000001',
        'b1000000-0000-0000-0000-000000000001',
        1, '2025-11-20 09:00:00+00', 30, 'no_show',
        'Blood pressure check'
    );

-- ---------------------------------------------------------------------------
-- encounters
-- ---------------------------------------------------------------------------
INSERT INTO encounters (
    id, patient_id, practitioner_id, appointment_id, department_id,
    type, started_at, ended_at, chief_complaint, clinical_notes
) VALUES
    (
        'd1000000-0000-0000-0000-000000000001',
        'a1000000-0000-0000-0000-000000000001',
        'b1000000-0000-0000-0000-000000000001',
        'c1000000-0000-0000-0000-000000000001', 1,
        'outpatient',
        '2025-11-10 09:05:00+00', '2025-11-10 09:35:00+00',
        'Annual physical exam',
        'Patient in good health overall. BP 118/76, HR 68. No acute concerns. Reviewed preventive screenings.'
    ),
    (
        'd1000000-0000-0000-0000-000000000002',
        'a1000000-0000-0000-0000-000000000002',
        'b1000000-0000-0000-0000-000000000001',
        'c1000000-0000-0000-0000-000000000002', 1,
        'outpatient',
        '2025-11-10 10:08:00+00', '2025-11-10 10:40:00+00',
        'Follow-up for hypertension',
        'BP 148/92 — poorly controlled on current regimen. Increased lisinopril dose. Ordered BMP and lipid panel.'
    ),
    (
        'd1000000-0000-0000-0000-000000000003',
        'a1000000-0000-0000-0000-000000000004',
        'b1000000-0000-0000-0000-000000000002',
        'c1000000-0000-0000-0000-000000000003', 2,
        'outpatient',
        '2025-11-11 14:10:00+00', '2025-11-11 15:00:00+00',
        'Chest pain on exertion',
        'Stable angina confirmed. ECG shows ST-segment changes. Echo ordered. Started aspirin and atorvastatin.'
    ),
    (
        'd1000000-0000-0000-0000-000000000004',
        'a1000000-0000-0000-0000-000000000003',
        'b1000000-0000-0000-0000-000000000004',
        'c1000000-0000-0000-0000-000000000004', 1,
        'outpatient',
        '2025-11-12 11:05:00+00', '2025-11-12 11:30:00+00',
        'Sore throat and fever',
        'Temp 38.4 °C. Throat red with exudate. Rapid strep positive. Prescribed amoxicillin.'
    ),
    (
        'd1000000-0000-0000-0000-000000000005',
        'a1000000-0000-0000-0000-000000000005',
        'b1000000-0000-0000-0000-000000000001',
        'c1000000-0000-0000-0000-000000000005', 1,
        'outpatient',
        '2025-11-13 09:35:00+00', '2025-11-13 10:00:00+00',
        'Routine contraception review',
        'No concerns. Continued oral contraceptive. Cervical screening up-to-date.'
    ),
    (
        'd1000000-0000-0000-0000-000000000006',
        'a1000000-0000-0000-0000-000000000006',
        'b1000000-0000-0000-0000-000000000002',
        'c1000000-0000-0000-0000-000000000006', 2,
        'outpatient',
        '2025-11-14 15:05:00+00', '2025-11-14 16:00:00+00',
        'Post-op cardiac follow-up',
        'Six-week post-CABG review. Wound healing well. EF improved to 55%. Continue dual antiplatelet therapy.'
    ),
    (
        'd1000000-0000-0000-0000-000000000007',
        'a1000000-0000-0000-0000-000000000007',
        'b1000000-0000-0000-0000-000000000003',
        NULL, 3,
        'emergency',
        '2025-11-15 02:20:00+00', '2025-11-15 05:45:00+00',
        'Hypoglycaemia — blood glucose 2.1 mmol/L',
        'Patient brought in by ambulance. Altered consciousness. IV dextrose administered. Glucose stabilised. Adjusted insulin regimen. Discharged with endocrinology referral.'
    ),
    (
        'd1000000-0000-0000-0000-000000000008',
        'a1000000-0000-0000-0000-000000000008',
        'b1000000-0000-0000-0000-000000000003',
        NULL, 3,
        'emergency',
        '2025-11-18 21:00:00+00', '2025-11-18 23:30:00+00',
        'Severe abdominal pain',
        'RUQ tenderness on palpation. Ultrasound confirms acute cholecystitis. Surgical referral placed. IV antibiotics initiated.'
    );

-- ---------------------------------------------------------------------------
-- diagnoses
-- ---------------------------------------------------------------------------
INSERT INTO diagnoses (id, encounter_id, code, description, is_primary, noted_at) VALUES
    -- Encounter 1: Annual physical — no active diagnoses recorded
    (
        'e1000000-0000-0000-0000-000000000001',
        'd1000000-0000-0000-0000-000000000001',
        'Z00.00', 'Encounter for general adult medical examination without abnormal findings',
        TRUE, '2025-11-10 09:30:00+00'
    ),
    -- Encounter 2: Hypertension
    (
        'e1000000-0000-0000-0000-000000000002',
        'd1000000-0000-0000-0000-000000000002',
        'I10', 'Essential (primary) hypertension',
        TRUE, '2025-11-10 10:35:00+00'
    ),
    -- Encounter 3: Stable angina + hyperlipidaemia
    (
        'e1000000-0000-0000-0000-000000000003',
        'd1000000-0000-0000-0000-000000000003',
        'I20.9', 'Angina pectoris, unspecified',
        TRUE, '2025-11-11 14:55:00+00'
    ),
    (
        'e1000000-0000-0000-0000-000000000004',
        'd1000000-0000-0000-0000-000000000003',
        'E78.5', 'Hyperlipidaemia, unspecified',
        FALSE, '2025-11-11 14:55:00+00'
    ),
    -- Encounter 4: Strep throat
    (
        'e1000000-0000-0000-0000-000000000005',
        'd1000000-0000-0000-0000-000000000004',
        'J02.0', 'Streptococcal pharyngitis',
        TRUE, '2025-11-12 11:25:00+00'
    ),
    -- Encounter 5: Routine review — no abnormal findings
    (
        'e1000000-0000-0000-0000-000000000006',
        'd1000000-0000-0000-0000-000000000005',
        'Z30.09', 'Encounter for other general counseling and advice on contraception',
        TRUE, '2025-11-13 09:58:00+00'
    ),
    -- Encounter 6: Post-CABG follow-up
    (
        'e1000000-0000-0000-0000-000000000007',
        'd1000000-0000-0000-0000-000000000006',
        'Z48.812', 'Encounter for surgical aftercare following surgery on the circulatory system',
        TRUE, '2025-11-14 15:55:00+00'
    ),
    -- Encounter 7: Hypoglycaemia
    (
        'e1000000-0000-0000-0000-000000000008',
        'd1000000-0000-0000-0000-000000000007',
        'E11.649', 'Type 2 diabetes mellitus with hypoglycaemia without coma',
        TRUE, '2025-11-15 03:00:00+00'
    ),
    -- Encounter 8: Acute cholecystitis
    (
        'e1000000-0000-0000-0000-000000000009',
        'd1000000-0000-0000-0000-000000000008',
        'K81.0', 'Acute cholecystitis',
        TRUE, '2025-11-18 22:00:00+00'
    ),
    (
        'e1000000-0000-0000-0000-000000000010',
        'd1000000-0000-0000-0000-000000000008',
        'K80.20', 'Calculus of gallbladder without cholecystitis without obstruction',
        FALSE, '2025-11-18 22:00:00+00'
    );

-- ---------------------------------------------------------------------------
-- medications
-- ---------------------------------------------------------------------------
INSERT INTO medications (id, rxnorm_code, name, generic_name, drug_class, dosage_form, strength, is_controlled) VALUES
    (1,  '29046',  'Lisinopril 10 mg',         'Lisinopril',      'ACE Inhibitor',               'tablet',    '10 mg',         FALSE),
    (2,  '29047',  'Lisinopril 20 mg',         'Lisinopril',      'ACE Inhibitor',               'tablet',    '20 mg',         FALSE),
    (3,  '41493',  'Atorvastatin 40 mg',       'Atorvastatin',    'Statin',                      'tablet',    '40 mg',         FALSE),
    (4,  '308460', 'Aspirin 81 mg',            'Aspirin',         'Antiplatelet / NSAID',        'tablet',    '81 mg',         FALSE),
    (5,  '723',    'Amoxicillin 500 mg',       'Amoxicillin',     'Penicillin Antibiotic',       'capsule',   '500 mg',        FALSE),
    (6,  '161',    'Amlodipine 5 mg',          'Amlodipine',      'Calcium Channel Blocker',     'tablet',    '5 mg',          FALSE),
    (7,  '56360',  'Metformin 500 mg',         'Metformin',       'Biguanide Antidiabetic',      'tablet',    '500 mg',        FALSE),
    (8,  '274783', 'Insulin Glargine 100 U/mL','Insulin Glargine','Long-Acting Insulin',         'injection', '100 U/mL',      FALSE),
    (9,  '892566', 'Ceftriaxone 1 g',          'Ceftriaxone',     'Cephalosporin Antibiotic',    'injection', '1 g',           FALSE),
    (10, '616257', 'Clopidogrel 75 mg',        'Clopidogrel',     'Antiplatelet',                'tablet',    '75 mg',         FALSE),
    (11, '866924', 'Ibuprofen 400 mg',         'Ibuprofen',       'NSAID',                       'tablet',    '400 mg',        FALSE),
    (12, '977425', 'Omeprazole 20 mg',         'Omeprazole',      'Proton Pump Inhibitor',       'capsule',   '20 mg',         FALSE);

SELECT setval('medications_id_seq', 12);

-- ---------------------------------------------------------------------------
-- prescriptions
-- ---------------------------------------------------------------------------
INSERT INTO prescriptions (
    id, encounter_id, medication_id, prescribed_by,
    dosage, frequency, route, duration_days, refills_allowed, instructions, status
) VALUES
    -- Encounter 2: increase lisinopril for hypertension
    (
        'f1000000-0000-0000-0000-000000000001',
        'd1000000-0000-0000-0000-000000000002', 2,
        'b1000000-0000-0000-0000-000000000001',
        '20 mg', 'once daily', 'oral', 90, 2,
        'Take in the morning. Monitor blood pressure at home.', 'active'
    ),
    -- Encounter 3: aspirin + atorvastatin for angina
    (
        'f1000000-0000-0000-0000-000000000002',
        'd1000000-0000-0000-0000-000000000003', 4,
        'b1000000-0000-0000-0000-000000000002',
        '81 mg', 'once daily', 'oral', NULL, 5,
        'Take with food. Do not stop without consulting your cardiologist.', 'active'
    ),
    (
        'f1000000-0000-0000-0000-000000000003',
        'd1000000-0000-0000-0000-000000000003', 3,
        'b1000000-0000-0000-0000-000000000002',
        '40 mg', 'once daily at bedtime', 'oral', NULL, 5,
        'Avoid grapefruit juice. Report any unexplained muscle pain.', 'active'
    ),
    -- Encounter 4: amoxicillin for strep throat
    (
        'f1000000-0000-0000-0000-000000000004',
        'd1000000-0000-0000-0000-000000000004', 5,
        'b1000000-0000-0000-0000-000000000004',
        '500 mg', 'three times daily', 'oral', 10, 0,
        'Complete the full course even if symptoms improve.', 'completed'
    ),
    -- Encounter 6: dual antiplatelet post-CABG
    (
        'f1000000-0000-0000-0000-000000000005',
        'd1000000-0000-0000-0000-000000000006', 4,
        'b1000000-0000-0000-0000-000000000002',
        '81 mg', 'once daily', 'oral', NULL, 5,
        'Do not stop unless instructed by your cardiologist.', 'active'
    ),
    (
        'f1000000-0000-0000-0000-000000000006',
        'd1000000-0000-0000-0000-000000000006', 10,
        'b1000000-0000-0000-0000-000000000002',
        '75 mg', 'once daily', 'oral', NULL, 5,
        'Continue for 12 months post-CABG. Report any unusual bleeding.', 'active'
    ),
    -- Encounter 7: adjust insulin regimen post-hypoglycaemia
    (
        'f1000000-0000-0000-0000-000000000007',
        'd1000000-0000-0000-0000-000000000007', 8,
        'b1000000-0000-0000-0000-000000000003',
        '16 U', 'once daily at bedtime', 'subcutaneous injection', NULL, 3,
        'Reduced dose from 20 U. Monitor fasting glucose daily. Seek emergency care if <3.0 mmol/L.', 'active'
    ),
    (
        'f1000000-0000-0000-0000-000000000008',
        'd1000000-0000-0000-0000-000000000007', 7,
        'b1000000-0000-0000-0000-000000000003',
        '500 mg', 'twice daily with meals', 'oral', NULL, 3,
        'Take with food to reduce GI side effects.', 'active'
    ),
    -- Encounter 8: IV antibiotics for cholecystitis
    (
        'f1000000-0000-0000-0000-000000000009',
        'd1000000-0000-0000-0000-000000000008', 9,
        'b1000000-0000-0000-0000-000000000003',
        '1 g', 'once every 24 hours', 'IV', 3, 0,
        'Administer over 30 minutes IV infusion. Monitor renal function.', 'completed'
    ),
    -- Encounter 8: omeprazole for gastric protection
    (
        'f1000000-0000-0000-0000-000000000010',
        'd1000000-0000-0000-0000-000000000008', 12,
        'b1000000-0000-0000-0000-000000000003',
        '20 mg', 'once daily before breakfast', 'oral', 28, 1,
        'Take 30 minutes before the first meal of the day.', 'active'
    );

-- ---------------------------------------------------------------------------
-- lab_orders
-- ---------------------------------------------------------------------------
INSERT INTO lab_orders (
    id, encounter_id, ordered_by, panel_name, loinc_code, priority, status,
    ordered_at, collected_at
) VALUES
    -- Encounter 2: BMP and lipid panel for hypertension management
    (
        'g1000000-0000-0000-0000-000000000001',
        'd1000000-0000-0000-0000-000000000002',
        'b1000000-0000-0000-0000-000000000001',
        'Basic Metabolic Panel (BMP)', '24323-8', 'routine', 'resulted',
        '2025-11-10 10:38:00+00', '2025-11-10 11:00:00+00'
    ),
    (
        'g1000000-0000-0000-0000-000000000002',
        'd1000000-0000-0000-0000-000000000002',
        'b1000000-0000-0000-0000-000000000001',
        'Lipid Panel', '57698-3', 'routine', 'resulted',
        '2025-11-10 10:38:00+00', '2025-11-10 11:00:00+00'
    ),
    -- Encounter 3: Cardiac troponin and ECG interpretation
    (
        'g1000000-0000-0000-0000-000000000003',
        'd1000000-0000-0000-0000-000000000003',
        'b1000000-0000-0000-0000-000000000002',
        'Troponin I (high-sensitivity)', '89579-7', 'urgent', 'resulted',
        '2025-11-11 14:20:00+00', '2025-11-11 14:35:00+00'
    ),
    -- Encounter 3: Echo — not a lab test but modelled as ordered investigation
    (
        'g1000000-0000-0000-0000-000000000004',
        'd1000000-0000-0000-0000-000000000003',
        'b1000000-0000-0000-0000-000000000002',
        'Echocardiogram', '34552-0', 'routine', 'ordered',
        '2025-11-11 14:55:00+00', NULL
    ),
    -- Encounter 7: Emergency glucose and HbA1c
    (
        'g1000000-0000-0000-0000-000000000005',
        'd1000000-0000-0000-0000-000000000007',
        'b1000000-0000-0000-0000-000000000003',
        'Blood Glucose (Point of Care)', '2339-0', 'stat', 'resulted',
        '2025-11-15 02:22:00+00', '2025-11-15 02:23:00+00'
    ),
    (
        'g1000000-0000-0000-0000-000000000006',
        'd1000000-0000-0000-0000-000000000007',
        'b1000000-0000-0000-0000-000000000003',
        'Haemoglobin A1c (HbA1c)', '4548-4', 'urgent', 'resulted',
        '2025-11-15 02:25:00+00', '2025-11-15 02:30:00+00'
    ),
    -- Encounter 8: Liver function tests and ultrasound for cholecystitis
    (
        'g1000000-0000-0000-0000-000000000007',
        'd1000000-0000-0000-0000-000000000008',
        'b1000000-0000-0000-0000-000000000003',
        'Liver Function Tests (LFT)', '1742-6', 'urgent', 'resulted',
        '2025-11-18 21:05:00+00', '2025-11-18 21:15:00+00'
    ),
    (
        'g1000000-0000-0000-0000-000000000008',
        'd1000000-0000-0000-0000-000000000008',
        'b1000000-0000-0000-0000-000000000003',
        'White Blood Cell Count (WBC)', '6690-2', 'urgent', 'resulted',
        '2025-11-18 21:05:00+00', '2025-11-18 21:15:00+00'
    );

-- ---------------------------------------------------------------------------
-- lab_results
-- ---------------------------------------------------------------------------
INSERT INTO lab_results (
    id, lab_order_id, test_name, loinc_code,
    value, unit, reference_range, is_abnormal, resulted_at
) VALUES
    -- BMP results (encounter 2)
    (
        'h1000000-0000-0000-0000-000000000001',
        'g1000000-0000-0000-0000-000000000001',
        'Serum Creatinine', '2160-0',
        '1.1', 'mg/dL', '0.7–1.2 mg/dL', FALSE,
        '2025-11-10 12:30:00+00'
    ),
    (
        'h1000000-0000-0000-0000-000000000002',
        'g1000000-0000-0000-0000-000000000001',
        'Serum Potassium', '2823-3',
        '3.4', 'mEq/L', '3.5–5.0 mEq/L', TRUE,
        '2025-11-10 12:30:00+00'
    ),
    -- Lipid panel results (encounter 2)
    (
        'h1000000-0000-0000-0000-000000000003',
        'g1000000-0000-0000-0000-000000000002',
        'Total Cholesterol', '2093-3',
        '242', 'mg/dL', '<200 mg/dL', TRUE,
        '2025-11-10 12:35:00+00'
    ),
    (
        'h1000000-0000-0000-0000-000000000004',
        'g1000000-0000-0000-0000-000000000002',
        'LDL Cholesterol', '2089-1',
        '158', 'mg/dL', '<100 mg/dL', TRUE,
        '2025-11-10 12:35:00+00'
    ),
    -- Troponin result (encounter 3)
    (
        'h1000000-0000-0000-0000-000000000005',
        'g1000000-0000-0000-0000-000000000003',
        'Troponin I (high-sensitivity)', '89579-7',
        '0.012', 'ng/mL', '<0.040 ng/mL', FALSE,
        '2025-11-11 15:05:00+00'
    ),
    -- Blood glucose — STAT (encounter 7)
    (
        'h1000000-0000-0000-0000-000000000006',
        'g1000000-0000-0000-0000-000000000005',
        'Blood Glucose', '2339-0',
        '2.1', 'mmol/L', '3.9–7.8 mmol/L', TRUE,
        '2025-11-15 02:24:00+00'
    ),
    -- HbA1c (encounter 7)
    (
        'h1000000-0000-0000-0000-000000000007',
        'g1000000-0000-0000-0000-000000000006',
        'Haemoglobin A1c', '4548-4',
        '9.2', '%', '<7.0%', TRUE,
        '2025-11-15 03:10:00+00'
    ),
    -- LFT results (encounter 8)
    (
        'h1000000-0000-0000-0000-000000000008',
        'g1000000-0000-0000-0000-000000000007',
        'Alanine Aminotransferase (ALT)', '1742-6',
        '78', 'U/L', '7–56 U/L', TRUE,
        '2025-11-18 22:10:00+00'
    ),
    (
        'h1000000-0000-0000-0000-000000000009',
        'g1000000-0000-0000-0000-000000000007',
        'Total Bilirubin', '1975-2',
        '2.4', 'mg/dL', '0.1–1.2 mg/dL', TRUE,
        '2025-11-18 22:10:00+00'
    ),
    -- WBC (encounter 8)
    (
        'h1000000-0000-0000-0000-000000000010',
        'g1000000-0000-0000-0000-000000000008',
        'White Blood Cell Count', '6690-2',
        '14.8', '× 10³/µL', '4.5–11.0 × 10³/µL', TRUE,
        '2025-11-18 22:10:00+00'
    ),
    -- Annual physical — within-normal CBC items (encounter 1 — extra)
    (
        'h1000000-0000-0000-0000-000000000011',
        'g1000000-0000-0000-0000-000000000001',
        'Sodium', '2951-2',
        '139', 'mEq/L', '136–145 mEq/L', FALSE,
        '2025-11-10 12:30:00+00'
    ),
    (
        'h1000000-0000-0000-0000-000000000012',
        'g1000000-0000-0000-0000-000000000001',
        'Blood Urea Nitrogen (BUN)', '3094-0',
        '18', 'mg/dL', '7–25 mg/dL', FALSE,
        '2025-11-10 12:30:00+00'
    );

COMMIT;
