-- ============================================
-- רום מדיקל – סכמת בסיס נתונים
-- הרץ את הקובץ הזה ב-Supabase SQL Editor
-- ============================================

-- פרופילי משתמשים
CREATE TABLE IF NOT EXISTS profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email TEXT,
  full_name TEXT,
  role TEXT DEFAULT 'secretary', -- admin | doctor | secretary
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- לידים
CREATE TABLE IF NOT EXISTS leads (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  phone TEXT NOT NULL,
  full_name TEXT NOT NULL,
  source TEXT DEFAULT 'phone', -- phone | whatsapp | email
  doctor TEXT,
  secretary TEXT,
  appointment_date DATE,
  appointment_time TIME,
  appointment_done BOOLEAN,
  notes TEXT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- משימות
CREATE TABLE IF NOT EXISTS tasks (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  description TEXT NOT NULL,
  owner TEXT NOT NULL,
  due_date DATE,
  priority TEXT DEFAULT 'mid', -- high | mid | low
  status TEXT DEFAULT 'open', -- open | done
  patient_name TEXT,
  patient_phone TEXT,
  from_leads BOOLEAN DEFAULT FALSE,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- תורים
CREATE TABLE IF NOT EXISTS appointments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  patient_name TEXT NOT NULL,
  patient_phone TEXT,
  doctor TEXT,
  date DATE NOT NULL,
  time TIME,
  status TEXT DEFAULT 'pending', -- pending | done | cancelled
  review_sent BOOLEAN DEFAULT FALSE,
  deduction_amount INTEGER DEFAULT 0,
  deduction_items JSONB,
  lead_id UUID REFERENCES leads(id),
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- פעולות / מחירון
CREATE TABLE IF NOT EXISTS procedures (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  price INTEGER NOT NULL DEFAULT 0,
  doctors TEXT,
  requires_followup BOOLEAN DEFAULT FALSE,
  followup_days INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- מלאי ציוד
CREATE TABLE IF NOT EXISTS inventory (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT DEFAULT 'medical', -- medical | office | medicine
  quantity INTEGER DEFAULT 0,
  min_quantity INTEGER DEFAULT 10,
  desired_quantity INTEGER,
  price_no_vat NUMERIC(10,2),
  price_with_vat NUMERIC(10,2),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- טיפולים מיוחדים
CREATE TABLE IF NOT EXISTS treatments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  patient_name TEXT NOT NULL,
  doctor TEXT,
  procedure_name TEXT,
  status TEXT DEFAULT 'active', -- active | done
  steps JSONB,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- סיכום הכנסות
CREATE TABLE IF NOT EXISTS income_summary (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  doctor TEXT NOT NULL,
  month TEXT,
  gross INTEGER DEFAULT 0,
  expenses INTEGER DEFAULT 0,
  overhead INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- רופאים – מידע קריטי
CREATE TABLE IF NOT EXISTS doctors (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  specialty TEXT,
  work_days TEXT,
  hours TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- הפעלת Row Level Security (RLS)
-- ============================================
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE procedures ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE treatments ENABLE ROW LEVEL SECURITY;
ALTER TABLE income_summary ENABLE ROW LEVEL SECURITY;
ALTER TABLE doctors ENABLE ROW LEVEL SECURITY;

-- מדיניות: משתמש מחובר רואה הכל
CREATE POLICY "authenticated_all" ON profiles FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all" ON leads FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all" ON tasks FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all" ON appointments FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all" ON procedures FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all" ON inventory FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all" ON treatments FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all" ON income_summary FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "authenticated_all" ON doctors FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- ============================================
-- נתוני דוגמה ראשוניים
-- ============================================

-- פעולות לדוגמה
INSERT INTO procedures (name, price, doctors, requires_followup, followup_days) VALUES
  ('הזרקת היאלורון', 1200, 'ד"ר כהן, ד"ר לוי', TRUE, 14),
  ('בוטוקס', 900, 'ד"ר כהן', TRUE, 21),
  ('ייעוץ ראשוני', 350, 'כל הרופאים', FALSE, NULL),
  ('פיזיותרפיה', 280, 'ד"ר מזרחי', FALSE, NULL),
  ('טיפול לייזר', 1800, 'ד"ר לוי', TRUE, 30);

-- מלאי לדוגמה
INSERT INTO inventory (name, category, quantity, min_quantity, desired_quantity, price_no_vat, price_with_vat) VALUES
  ('כפפות לטקס M', 'medical', 15, 50, 200, 45, 52),
  ('מחטי אינסולין', 'medical', 30, 50, 150, 12, 14),
  ('אלכוהול 70%', 'medical', 2, 10, 30, 18, 21),
  ('גאזה סטרילית', 'medical', 180, 50, 300, 8, 9),
  ('ניירת A4', 'office', 5, 10, 50, 25, 29);

-- רופאים לדוגמה
INSERT INTO doctors (name, specialty, work_days, hours, notes) VALUES
  ('ד"ר כהן', 'רפואה אסתטית', 'א, ג, ה', '09:00–17:00', 'אינו עונה לשיחות חוזרות בימי ג'' אחה"צ. יש לתאם 48 שעות מראש.'),
  ('ד"ר לוי', 'עור ולייזר', 'ב, ד', '10:00–18:00', 'מקבל מטופלים ממליצים בלבד מחוץ לתורים הרגילים.'),
  ('ד"ר מזרחי', 'פיזיותרפיה', 'א, ב, ג, ד, ה', '08:00–16:00', NULL);

-- הכנסות לדוגמה (אפריל 2025)
INSERT INTO income_summary (doctor, month, gross, expenses, overhead) VALUES
  ('ד"ר כהן', '2025-04', 38000, 2800, 4500),
  ('ד"ר לוי', '2025-04', 27500, 2100, 4500),
  ('ד"ר מזרחי', '2025-04', 19000, 1300, 3000);

-- ============================================
-- פונקציה: יצירת פרופיל אוטומטי עם הרשמה
-- ============================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, role)
  VALUES (new.id, new.email, new.raw_user_meta_data->>'full_name', COALESCE(new.raw_user_meta_data->>'role', 'secretary'));
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
