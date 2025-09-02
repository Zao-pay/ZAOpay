
-- ZAO PAY Database Schema for Supabase
-- This script should be run in the Supabase SQL editor

-- Create tables with proper permissions
CREATE TABLE IF NOT EXISTS user_profiles (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    home_address TEXT,
    cash_tag VARCHAR(20) UNIQUE NOT NULL,
    profile_photo TEXT,
    is_premium BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User Wallets Table
CREATE TABLE IF NOT EXISTS user_wallets (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
    balance DECIMAL(15,2) DEFAULT 0.00,
    currency VARCHAR(3) DEFAULT 'NGN',
    flutterwave_account_number VARCHAR(20),
    flutterwave_bank_name VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Transactions Table
CREATE TABLE IF NOT EXISTS transactions (
    id SERIAL PRIMARY KEY,
    transaction_ref VARCHAR(100) UNIQUE NOT NULL DEFAULT ('TXN-' || extract(epoch from now()) || '-' || floor(random() * 10000)),
    sender_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    receiver_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    amount DECIMAL(15,2) NOT NULL,
    fee DECIMAL(15,2) DEFAULT 0.00,
    transaction_type VARCHAR(20) NOT NULL, -- 'transfer', 'deposit', 'withdrawal', 'request'
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'completed', 'failed', 'cancelled'
    note TEXT,
    flutterwave_ref VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Money Requests Table
CREATE TABLE IF NOT EXISTS money_requests (
    id SERIAL PRIMARY KEY,
    request_ref VARCHAR(100) UNIQUE NOT NULL DEFAULT ('REQ-' || extract(epoch from now()) || '-' || floor(random() * 10000)),
    requester_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    requested_from_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    reason TEXT NOT NULL,
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'accepted', 'declined', 'expired'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '7 days'),
    resolved_at TIMESTAMP WITH TIME ZONE
);

-- Virtual Cards Table
CREATE TABLE IF NOT EXISTS virtual_cards (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    card_id VARCHAR(100) UNIQUE NOT NULL,
    card_number VARCHAR(19) NOT NULL,
    expiry_month VARCHAR(2) NOT NULL,
    expiry_year VARCHAR(4) NOT NULL,
    cvv VARCHAR(3) NOT NULL,
    card_type VARCHAR(20) DEFAULT 'VISA',
    status VARCHAR(20) DEFAULT 'active', -- 'active', 'blocked', 'expired'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Withdrawal Requests Table
CREATE TABLE IF NOT EXISTS withdrawal_requests (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    bank_code VARCHAR(10) NOT NULL,
    account_number VARCHAR(20) NOT NULL,
    account_name VARCHAR(255) NOT NULL,
    flutterwave_ref VARCHAR(255),
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'processing', 'completed', 'failed'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    processed_at TIMESTAMP WITH TIME ZONE
);

-- Create Indexes for Performance
CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON user_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_cash_tag ON user_profiles(cash_tag);
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON user_profiles(email);
CREATE INDEX IF NOT EXISTS idx_user_profiles_phone ON user_profiles(phone_number);

CREATE INDEX IF NOT EXISTS idx_user_wallets_user_id ON user_wallets(user_id);

CREATE INDEX IF NOT EXISTS idx_transactions_sender_id ON transactions(sender_id);
CREATE INDEX IF NOT EXISTS idx_transactions_receiver_id ON transactions(receiver_id);
CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON transactions(created_at);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON transactions(status);

CREATE INDEX IF NOT EXISTS idx_money_requests_requester_id ON money_requests(requester_id);
CREATE INDEX IF NOT EXISTS idx_money_requests_requested_from_id ON money_requests(requested_from_id);
CREATE INDEX IF NOT EXISTS idx_money_requests_status ON money_requests(status);

CREATE INDEX IF NOT EXISTS idx_virtual_cards_user_id ON virtual_cards(user_id);

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated;

-- Enable Row Level Security
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE money_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE virtual_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE withdrawal_requests ENABLE ROW LEVEL SECURITY;

-- Row Level Security Policies
-- User Profiles Policies
DROP POLICY IF EXISTS "Users can view own profile" ON user_profiles;
CREATE POLICY "Users can view own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view public profiles for search" ON user_profiles;
CREATE POLICY "Users can view public profiles for search" ON user_profiles
    FOR SELECT USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;
CREATE POLICY "Users can update own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own profile" ON user_profiles;
CREATE POLICY "Users can insert own profile" ON user_profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- User Wallets Policies
DROP POLICY IF EXISTS "Users can view own wallet" ON user_wallets;
CREATE POLICY "Users can view own wallet" ON user_wallets
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own wallet" ON user_wallets;
CREATE POLICY "Users can update own wallet" ON user_wallets
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own wallet" ON user_wallets;
CREATE POLICY "Users can insert own wallet" ON user_wallets
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Transactions Policies
DROP POLICY IF EXISTS "Users can view own transactions" ON transactions;
CREATE POLICY "Users can view own transactions" ON transactions
    FOR SELECT USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

DROP POLICY IF EXISTS "Users can insert transactions" ON transactions;
CREATE POLICY "Users can insert transactions" ON transactions
    FOR INSERT WITH CHECK (auth.uid() = sender_id);

-- Money Requests Policies
DROP POLICY IF EXISTS "Users can view own requests" ON money_requests;
CREATE POLICY "Users can view own requests" ON money_requests
    FOR SELECT USING (auth.uid() = requester_id OR auth.uid() = requested_from_id);

DROP POLICY IF EXISTS "Users can insert requests" ON money_requests;
CREATE POLICY "Users can insert requests" ON money_requests
    FOR INSERT WITH CHECK (auth.uid() = requester_id);

DROP POLICY IF EXISTS "Users can update requests" ON money_requests;
CREATE POLICY "Users can update requests" ON money_requests
    FOR UPDATE USING (auth.uid() = requested_from_id);

-- Virtual Cards Policies
DROP POLICY IF EXISTS "Users can view own cards" ON virtual_cards;
CREATE POLICY "Users can view own cards" ON virtual_cards
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own cards" ON virtual_cards;
CREATE POLICY "Users can insert own cards" ON virtual_cards
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Withdrawal Requests Policies
DROP POLICY IF EXISTS "Users can view own withdrawals" ON withdrawal_requests;
CREATE POLICY "Users can view own withdrawals" ON withdrawal_requests
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert withdrawals" ON withdrawal_requests;
CREATE POLICY "Users can insert withdrawals" ON withdrawal_requests
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Functions for automatic updates
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updated_at
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON user_profiles;
CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON user_profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_user_wallets_updated_at ON user_wallets;
CREATE TRIGGER update_user_wallets_updated_at BEFORE UPDATE ON user_wallets FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_transactions_updated_at ON transactions;
CREATE TRIGGER update_transactions_updated_at BEFORE UPDATE ON transactions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to generate unique cash tags
CREATE OR REPLACE FUNCTION generate_unique_cash_tag()
RETURNS TEXT AS $$
DECLARE
    new_tag TEXT;
    tag_exists BOOLEAN;
    counter INTEGER := 0;
BEGIN
    LOOP
        new_tag := 'ZAO-' || upper(substring(md5(random()::text || counter::text) from 1 for 5));
        
        SELECT EXISTS(SELECT 1 FROM user_profiles WHERE cash_tag = new_tag) INTO tag_exists;
        
        IF NOT tag_exists THEN
            EXIT;
        END IF;
        
        counter := counter + 1;
        
        -- Prevent infinite loop
        IF counter > 1000 THEN
            new_tag := 'ZAO-' || upper(substring(md5(random()::text || now()::text) from 1 for 8));
            EXIT;
        END IF;
    END LOOP;
    
    RETURN new_tag;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to calculate transaction fees
CREATE OR REPLACE FUNCTION calculate_transaction_fee(amount DECIMAL)
RETURNS DECIMAL AS $$
BEGIN
    RETURN ROUND(amount * 0.02, 2); -- 2% fee
END;
$$ LANGUAGE plpgsql;
