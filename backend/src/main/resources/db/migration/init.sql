-- enumerated types
CREATE TYPE plan_type AS ENUM ('free', 'pro');
CREATE TYPE account_type AS ENUM ('checking', 'savings', 'crypto', 'investment', 'credit');
CREATE TYPE category_type AS ENUM ('income', 'expense');
CREATE TYPE transaction_type AS ENUM ('income', 'expense', 'transfer');
CREATE TYPE budget_period_type AS ENUM ('monthly', 'yearly');
CREATE TYPE goal_status AS ENUM ('on-track', 'behind', 'done');
CREATE TYPE frequency_type AS ENUM ('daily', 'weekly', 'monthly', 'yearly');
CREATE TYPE insight_type AS ENUM ('warning', 'positive', 'info');
CREATE TYPE import_status AS ENUM ('pending', 'mapping', 'done', 'error');

-- global function for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$ language 'plpgsql';

-- Main tables
-- Users
CREATE TABLE IF NOT EXISTS user (
                        user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                        -- using UUID more security bc generating 36 random characters than serial
                        email VARCHAR(255) UNIQUE NOT NULL
                            CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
                        name VARCHAR(255) NOT NULL,
                        avatar_url TEXT,
                        currency VARCHAR(3) DEFAULT 'EUR' NOT NULL,
                        locale VARCHAR(10) DEFAULT 'fr-FR' NOT NULL,
                        plan plan_type DEFAULT 'free' NOT NULL,
                        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
                        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- DTrigger for the users table
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON user
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ACCOUNTS
CREATE TABLE account (
                          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                          user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                          name VARCHAR(255) NOT NULL,
                          type account_type NOT NULL,
                          balance NUMERIC(15, 2) DEFAULT 0.00 NOT NULL,
                          color VARCHAR(7), -- Code Hex ex: #FF5733
                          institution VARCHAR(255),
                          currency VARCHAR(3) DEFAULT 'USD' NOT NULL,
                          is_active BOOLEAN DEFAULT TRUE NOT NULL,
                          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
                          updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TRIGGER update_accounts_updated_at
    BEFORE UPDATE ON account
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- categories (user_id NULL then system default
CREATE TABLE categorie (
                            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                            user_id UUID REFERENCES users(id) ON DELETE CASCADE,
                            name VARCHAR(255) NOT NULL,
                            icon VARCHAR(100),
                            color VARCHAR(7),
                            type category_type NOT NULL,
                            is_default BOOLEAN DEFAULT FALSE NOT NULL
);

-- Csv imports
CREATE TABLE csv_import (
                             id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                             user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                             account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
                             filename VARCHAR(255) NOT NULL,
                             status import_status DEFAULT 'pending' NOT NULL,
                             rows_total INT DEFAULT 0 NOT NULL,
                             rows_imported INT DEFAULT 0 NOT NULL,
                             rows_skipped INT DEFAULT 0 NOT NULL,
                             imported_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Transactions
CREATE TABLE transaction (
                              id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                              user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                              account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
                              category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
                              amount NUMERIC(15, 2) NOT NULL,
                              description TEXT,
                              date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
                              type transaction_type NOT NULL,
                              note TEXT,
                              is_recurring BOOLEAN DEFAULT FALSE NOT NULL,
                              import_id UUID REFERENCES csv_imports(id) ON DELETE SET NULL,
                              created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
                              updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TRIGGER update_transactions_updated_at
    BEFORE UPDATE ON transaction
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Transfer
CREATE TABLE transfer (
                           id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                           user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                           from_account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
                           to_account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
                           amount NUMERIC(15, 2) NOT NULL,
                           date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
                           note TEXT,
                           created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Budegt
CREATE TABLE budget (
                         id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                         user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                         category_id UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
                         amount NUMERIC(15, 2) NOT NULL,
                         period budget_period_type DEFAULT 'monthly' NOT NULL,
                         start_date DATE NOT NULL,
                         end_date DATE,
                         is_active BOOLEAN DEFAULT TRUE NOT NULL,
                         created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
                         updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TRIGGER update_budgets_updated_at
    BEFORE UPDATE ON budget
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Budget_periods (History)
CREATE TABLE budget_period (
                                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                                budget_id UUID NOT NULL REFERENCES budgets(id) ON DELETE CASCADE,
                                period_start DATE NOT NULL,
                                period_end DATE NOT NULL,
                                budgeted_amount NUMERIC(15, 2) NOT NULL,
                                spent_amount NUMERIC(15, 2) DEFAULT 0.00 NOT NULL
);

-- Goals
CREATE TABLE goal (
                       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                       user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                       name VARCHAR(255) NOT NULL,
                       icon VARCHAR(100),
                       target_amount NUMERIC(15, 2) NOT NULL,
                       current_amount NUMERIC(15, 2) DEFAULT 0.00 NOT NULL,
                       deadline DATE,
                       monthly_contribution NUMERIC(15, 2) DEFAULT 0.00 NOT NULL,
                       status goal_status DEFAULT 'on-track' NOT NULL,
                       account_id UUID REFERENCES accounts(id) ON DELETE SET NULL,
                       created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
                       updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TRIGGER update_goals_updated_at
    BEFORE UPDATE ON goal
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- GOAL_CONTRIBUTIONS
CREATE TABLE goal_contribution (
                                    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                                    goal_id UUID NOT NULL REFERENCES goals(id) ON DELETE CASCADE,
                                    amount NUMERIC(15, 2) NOT NULL,
                                    date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
                                    note TEXT
);

-- RECURRING_TRANSACTIONS
CREATE TABLE recurring_transaction (
                                        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                                        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                                        account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
                                        category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
                                        amount NUMERIC(15, 2) NOT NULL,
                                        description TEXT,
                                        frequency frequency_type NOT NULL,
                                        next_date DATE NOT NULL,
                                        is_active BOOLEAN DEFAULT TRUE NOT NULL,
                                        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
                                        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TRIGGER update_recurring_transactions_updated_at
    BEFORE UPDATE ON recurring_transaction
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- INSIGHTS
CREATE TABLE insight (
                          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                          user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                          type insight_type NOT NULL,
                          title VARCHAR(255) NOT NULL,
                          description TEXT,
                          category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
                          generated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
                          is_read BOOLEAN DEFAULT FALSE NOT NULL
);

-- CSV_COLUMN_MAPPINGS
CREATE TABLE csv_column_mapping (
                                     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                                     user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                                     account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
                                     column_date VARCHAR(100) NOT NULL,
                                     column_description VARCHAR(100) NOT NULL,
                                     column_amount VARCHAR(100) NOT NULL,
                                     column_category VARCHAR(100),
                                     date_format VARCHAR(50) DEFAULT 'YYYY-MM-DD' NOT NULL,
                                     created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
                                     updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TRIGGER update_csv_column_mappings_updated_at
    BEFORE UPDATE ON csv_column_mapping
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();