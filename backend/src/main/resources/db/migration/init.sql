-- =====================================================================
-- Enumerated types
-- =====================================================================
CREATE TYPE plan_type          AS ENUM ('FREE', 'PRO');
CREATE TYPE account_type       AS ENUM ('CHECKING', 'SAVINGS', 'CRYPTO', 'INVESTMENT', 'CREDIT');
CREATE TYPE category_type      AS ENUM ('INCOME', 'EXPENSE');
CREATE TYPE transaction_type   AS ENUM ('INCOME', 'EXPENSE', 'TRANSFER');
CREATE TYPE budget_period_type AS ENUM ('MONTHLY', 'YEARLY');
CREATE TYPE goal_status        AS ENUM ('ON_TRACK', 'BEHIND', 'DONE');
CREATE TYPE frequency_type     AS ENUM ('DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY');
CREATE TYPE insight_type       AS ENUM ('WARNING', 'POSITIVE', 'INFO');
CREATE TYPE import_status      AS ENUM ('PENDING', 'MAPPING', 'DONE', 'ERROR');

-- =====================================================================
-- Global function: keeps updated_at in sync on every UPDATE
-- =====================================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================
-- users  ("user" is a reserved word in PostgreSQL, so the table is "users")
-- UUID primary keys: harder to guess than sequential ids
-- =====================================================================
CREATE TABLE users (
                       user_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                       email      VARCHAR(255) UNIQUE NOT NULL
                           CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
                        name       VARCHAR(255) NOT NULL,
                        avatar_url TEXT,
                        currency   VARCHAR(3)  DEFAULT 'EUR'   NOT NULL,
                        locale     VARCHAR(10) DEFAULT 'fr-FR' NOT NULL,
                        plan       plan_type   DEFAULT 'free'  NOT NULL,
                        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
                        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================================
-- account
-- =====================================================================
CREATE TABLE account (
                         account_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                         user_id     UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
                         name        VARCHAR(255) NOT NULL,
                         type        account_type NOT NULL,
                         balance     NUMERIC(15, 2) DEFAULT 0.00 NOT NULL,
                         color       VARCHAR(7),                       -- hex code, e.g. #FF5733
                         institution VARCHAR(255),
                         currency    VARCHAR(3) DEFAULT 'EUR' NOT NULL,
                         is_active   BOOLEAN DEFAULT TRUE NOT NULL,
                         created_at  TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
                         updated_at  TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TRIGGER update_account_updated_at
    BEFORE UPDATE ON account
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================================
-- category (user_id NULL = system default category)
-- =====================================================================
CREATE TABLE category (
                          category_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                          user_id     UUID REFERENCES users(user_id) ON DELETE CASCADE,
                          name        VARCHAR(255) NOT NULL,
                          icon        VARCHAR(100),
                          color       VARCHAR(7),
                          type        category_type NOT NULL,
                          is_default  BOOLEAN DEFAULT FALSE NOT NULL
);

-- =====================================================================
-- csv_import
-- =====================================================================
CREATE TABLE csv_import (
                            csv_import_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                            user_id       UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
                            account_id    UUID NOT NULL REFERENCES account(account_id) ON DELETE CASCADE,
                            filename      VARCHAR(255) UNIQUE NOT NULL,
                            status        import_status DEFAULT 'pending' NOT NULL,
                            rows_total    INT DEFAULT 0 NOT NULL,
                            rows_imported INT DEFAULT 0 NOT NULL,
                            rows_skipped  INT DEFAULT 0 NOT NULL,
                            imported_at   TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- =====================================================================
-- transaction
-- =====================================================================
CREATE TABLE transaction (
                             transaction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                             user_id        UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
                             account_id     UUID NOT NULL REFERENCES account(account_id) ON DELETE CASCADE,
                             category_id    UUID REFERENCES category(category_id) ON DELETE SET NULL,
                             amount         NUMERIC(15, 2) NOT NULL,
                             description    TEXT,
                             date           TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
                             type           transaction_type NOT NULL,
                             note           TEXT,
                             is_recurring   BOOLEAN DEFAULT FALSE NOT NULL,
                             csv_import_id  UUID REFERENCES csv_import(csv_import_id) ON DELETE SET NULL,
                             created_at     TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
                             updated_at     TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TRIGGER update_transaction_updated_at
    BEFORE UPDATE ON transaction
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================================
-- transfer (between two accounts)
-- =====================================================================
CREATE TABLE transfer (
                          transfer_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                          user_id         UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
                          from_account_id UUID NOT NULL REFERENCES account(account_id) ON DELETE CASCADE,
                          to_account_id   UUID NOT NULL REFERENCES account(account_id) ON DELETE CASCADE,
                          amount          NUMERIC(15, 2) NOT NULL,
                          date            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
                          note            TEXT,
                          created_at      TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- =====================================================================
-- budget
-- =====================================================================
CREATE TABLE budget (
                        budget_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                        user_id     UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
                        category_id UUID NOT NULL REFERENCES category(category_id) ON DELETE CASCADE,
                        amount      NUMERIC(15, 2) NOT NULL,
                        period      budget_period_type DEFAULT 'monthly' NOT NULL,
                        start_date  DATE NOT NULL,
                        end_date    DATE,
                        is_active   BOOLEAN DEFAULT TRUE NOT NULL,
                        created_at  TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
                        updated_at  TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TRIGGER update_budget_updated_at
    BEFORE UPDATE ON budget
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================================
-- budget_period (history)
-- =====================================================================
CREATE TABLE budget_period (
                               budget_period_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                               budget_id        UUID NOT NULL REFERENCES budget(budget_id) ON DELETE CASCADE,
                               period_start     DATE NOT NULL,
                               period_end       DATE NOT NULL,
                               budgeted_amount  NUMERIC(15, 2) NOT NULL,
                               spent_amount     NUMERIC(15, 2) DEFAULT 0.00 NOT NULL
);

-- =====================================================================
-- goal
-- =====================================================================
CREATE TABLE goal (
                      goal_id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                      user_id              UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
                      name                 VARCHAR(255) NOT NULL,
                      icon                 VARCHAR(100),
                      target_amount        NUMERIC(15, 2) NOT NULL,
                      current_amount       NUMERIC(15, 2) DEFAULT 0.00 NOT NULL,
                      deadline             DATE,
                      monthly_contribution NUMERIC(15, 2) DEFAULT 0.00 NOT NULL,
                      status               goal_status DEFAULT 'on-track' NOT NULL,
                      account_id           UUID REFERENCES account(account_id) ON DELETE SET NULL,
                      created_at           TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
                      updated_at           TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TRIGGER update_goal_updated_at
    BEFORE UPDATE ON goal
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================================
-- goal_contribution
-- =====================================================================
CREATE TABLE goal_contribution (
                                   goal_contribution_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                                   goal_id              UUID NOT NULL REFERENCES goal(goal_id) ON DELETE CASCADE,
                                   amount               NUMERIC(15, 2) NOT NULL,
                                   date                 TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
                                   note                 TEXT
);

-- =====================================================================
-- recurring_transaction
-- =====================================================================
CREATE TABLE recurring_transaction (
                                       recurring_transaction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                                       user_id                  UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
                                       account_id               UUID NOT NULL REFERENCES account(account_id) ON DELETE CASCADE,
                                       category_id              UUID REFERENCES category(category_id) ON DELETE SET NULL,
                                       amount                   NUMERIC(15, 2) NOT NULL,
                                       description              TEXT,
                                       frequency                frequency_type NOT NULL,
                                       next_date                DATE NOT NULL,
                                       is_active                BOOLEAN DEFAULT TRUE NOT NULL,
                                       created_at               TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
                                       updated_at               TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TRIGGER update_recurring_transaction_updated_at
    BEFORE UPDATE ON recurring_transaction
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================================
-- insight
-- =====================================================================
CREATE TABLE insight (
                         insight_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                         user_id      UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
                         type         insight_type NOT NULL,
                         title        VARCHAR(255) NOT NULL,
                         description  TEXT,
                         category_id  UUID REFERENCES category(category_id) ON DELETE SET NULL,
                         generated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
                         is_read      BOOLEAN DEFAULT FALSE NOT NULL
);

-- =====================================================================
-- csv_column_mapping
-- =====================================================================
CREATE TABLE csv_column_mapping (
                                    csv_column_mapping_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                                    user_id               UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
                                    account_id            UUID NOT NULL REFERENCES account(account_id) ON DELETE CASCADE,
                                    column_date           VARCHAR(100) NOT NULL,
                                    column_description    VARCHAR(100) NOT NULL,
                                    column_amount         VARCHAR(100) NOT NULL,
                                    column_category       VARCHAR(100),
                                    date_format           VARCHAR(50) DEFAULT 'YYYY-MM-DD' NOT NULL,
                                    created_at            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
                                    updated_at            TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TRIGGER update_csv_column_mapping_updated_at
    BEFORE UPDATE ON csv_column_mapping
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();