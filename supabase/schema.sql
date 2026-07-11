-- Miva-Fid Supabase Schema
-- Run this in your Supabase SQL Editor

CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  name TEXT NOT NULL,
  phone TEXT,
  role TEXT DEFAULT 'client',
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS merchants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  address TEXT,
  slug TEXT UNIQUE,
  logo_url TEXT,
  cover_url TEXT,
  description TEXT,
  phone TEXT,
  whatsapp TEXT,
  instagram TEXT,
  facebook TEXT,
  tiktok TEXT,
  hours JSONB,
  color_primary TEXT DEFAULT '#4F46E5',
  color_secondary TEXT DEFAULT '#3730A3',
  loyalty_mode TEXT DEFAULT 'stamps',
  stamps_required INT DEFAULT 10,
  points_per_500fcfa INT DEFAULT 1,
  reward_description TEXT,
  reward_value_fcfa INT,
  google_review_url TEXT,
  show_review_button BOOLEAN DEFAULT false,
  stamp_design_type TEXT DEFAULT 'check',
  stamp_emoji TEXT DEFAULT '✨',
  stamp_icon TEXT DEFAULT 'check_rounded',
  card_decoration_pattern TEXT DEFAULT 'none',
  card_gradient_type TEXT DEFAULT 'linear',
  plan TEXT DEFAULT 'free',
  sms_remaining INT DEFAULT 100,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS loyalty_cards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID REFERENCES users(id) ON DELETE CASCADE,
  merchant_id UUID REFERENCES merchants(id) ON DELETE CASCADE,
  stamps_count INT DEFAULT 0,
  points_total INT DEFAULT 0,
  status TEXT DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(client_id, merchant_id)
);

CREATE TABLE IF NOT EXISTS stamps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  card_id UUID REFERENCES loyalty_cards(id) ON DELETE CASCADE,
  merchant_id UUID REFERENCES merchants(id),
  validated_by UUID REFERENCES users(id),
  validated_at TIMESTAMPTZ DEFAULT now()
);

-- Auto-increment stamps_count on new stamp
CREATE OR REPLACE FUNCTION increment_stamps_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE loyalty_cards
  SET stamps_count = stamps_count + 1
  WHERE id = NEW.card_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_stamp_inserted ON stamps;
CREATE TRIGGER on_stamp_inserted
  AFTER INSERT ON stamps
  FOR EACH ROW EXECUTE FUNCTION increment_stamps_count();

CREATE TABLE IF NOT EXISTS rewards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  card_id UUID REFERENCES loyalty_cards(id) ON DELETE CASCADE,
  client_id UUID REFERENCES users(id),
  merchant_id UUID REFERENCES merchants(id),
  unlocked_at TIMESTAMPTZ DEFAULT now(),
  redeemed_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  status TEXT DEFAULT 'available',
  redemption_code TEXT UNIQUE
);

CREATE TABLE IF NOT EXISTS sms_campaigns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  merchant_id UUID REFERENCES merchants(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  recipient_type TEXT,
  recipient_ids UUID[],
  recipients_count INT DEFAULT 0,
  status TEXT DEFAULT 'draft',
  scheduled_at TIMESTAMPTZ,
  sent_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- RLS Policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE merchants ENABLE ROW LEVEL SECURITY;
ALTER TABLE loyalty_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE stamps ENABLE ROW LEVEL SECURITY;
ALTER TABLE rewards ENABLE ROW LEVEL SECURITY;
ALTER TABLE sms_campaigns ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own profile" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON users FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Merchants readable by owner" ON merchants FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Merchants insertable by owner" ON merchants FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Merchants updatable by owner" ON merchants FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Loyalty cards readable by client or merchant" ON loyalty_cards
  FOR SELECT USING (
    auth.uid() = client_id OR
    EXISTS (SELECT 1 FROM merchants WHERE id = merchant_id AND user_id = auth.uid())
  );
CREATE POLICY "Loyalty cards insertable by client" ON loyalty_cards
  FOR INSERT WITH CHECK (auth.uid() = client_id);
CREATE POLICY "Loyalty cards updatable by merchant" ON loyalty_cards
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM merchants WHERE id = merchant_id AND user_id = auth.uid())
  );

CREATE POLICY "Stamps insertable by merchant" ON stamps
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM merchants WHERE id = merchant_id AND user_id = auth.uid())
  );
CREATE POLICY "Stamps readable by merchant" ON stamps
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM merchants WHERE id = merchant_id AND user_id = auth.uid())
  );

CREATE POLICY "Rewards readable by client or merchant" ON rewards
  FOR SELECT USING (
    auth.uid() = client_id OR
    EXISTS (SELECT 1 FROM merchants WHERE id = merchant_id AND user_id = auth.uid())
  );
CREATE POLICY "Rewards insertable by merchant" ON rewards
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM merchants WHERE id = merchant_id AND user_id = auth.uid())
  );
CREATE POLICY "Rewards updatable by merchant" ON rewards
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM merchants WHERE id = merchant_id AND user_id = auth.uid())
  );

CREATE POLICY "SMS campaigns by merchant" ON sms_campaigns
  FOR ALL USING (
    EXISTS (SELECT 1 FROM merchants WHERE id = merchant_id AND user_id = auth.uid())
  );
